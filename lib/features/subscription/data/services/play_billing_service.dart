import 'dart:async';

import 'package:invoice_kit/core/storage/hive_storage_service.dart';
import 'package:invoice_kit/core/storage/local_storage_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:invoice_kit/core/storage/secure_storage_service.dart';
import 'package:invoice_kit/features/subscription/data/datasources/subscription_supabase_datasource.dart';

/// Bridges Google Play Billing (`in_app_purchase`) into the existing
/// `SubscriptionStatus` domain entity. Lives in `data/` so the
/// presentation / domain layers never have to depend on the platform
/// billing SDK directly.
abstract class SubscriptionBillingService {
  Future<void> initialize();

  Future<List<BillingProduct>> loadProducts();

  Future<BillingPurchaseResult> purchase({
    required BillingProduct product,
    required String userId,
  });

  Future<BillingPurchaseResult> restore({required String userId});

  /// Emits whenever the underlying billing SDK reports a change in
  /// ownership (renewal, refund, etc.) so the bloc can re-sync.
  Stream<BillingPurchaseUpdate> get updates;
}

class BillingProduct {
  const BillingProduct({
    required this.productId,
    required this.title,
    required this.description,
    required this.price,
    required this.rawPrice,
  });

  final String productId;
  final String title;
  final String description;

  /// Formatted display string, e.g. `$4.99`.
  final String price;

  /// Machine-readable amount in the smallest currency unit.
  final double rawPrice;
}

enum BillingPurchaseStatus {
  success,
  pending,
  cancelled,
  failed,
  alreadyOwned,
  restored,
}

class BillingPurchaseResult {
  const BillingPurchaseResult({
    required this.status,
    this.purchaseToken,
    this.productId,
    this.message,
  });

  final BillingPurchaseStatus status;
  final String? purchaseToken;
  final String? productId;
  final String? message;
}

class BillingPurchaseUpdate {
  const BillingPurchaseUpdate({
    required this.status,
    this.purchaseToken,
    this.productId,
    this.expiryDate,
  });

  final BillingPurchaseStatus status;
  final String? purchaseToken;
  final String? productId;
  final DateTime? expiryDate;
}

/// Concrete billing implementation using the `in_app_purchase` package.
/// Wrapped so the rest of the app can swap in a stub during tests / on
/// platforms that don't have Google Play (iOS desktop, web, etc.).
class PlayBillingSubscriptionService implements SubscriptionBillingService {
  PlayBillingSubscriptionService({
    required LocalStorageService localStorage,
    required this.monthlyProductId,
    required this.yearlyProductId,
    required HiveStorageService hive,
    required SecureStorageService secure,
    required SubscriptionSupabaseDataSource supabase,
  });

  // final HiveStorageService _hive;
  // final LocalStorageService _local;
  // final SecureStorageService _secure;
  // final SubscriptionSupabaseDataSource _supabase;
  final String monthlyProductId;
  final String yearlyProductId;

  final StreamController<BillingPurchaseUpdate> _controller =
      StreamController<BillingPurchaseUpdate>.broadcast();

  InAppPurchase? _iap;

  @override
  Stream<BillingPurchaseUpdate> get updates => _controller.stream;

  @override
  Future<void> initialize() async {
    try {
      _iap = InAppPurchase.instance;
      _iap!.purchaseStream.listen(_onPurchaseUpdate);
    } on Object catch (_) {
      // Silent — billing unavailable surfaces later as a Failure on load.
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      final mapped = _mapStatus(p.status);
      _controller.add(
        BillingPurchaseUpdate(
          status: mapped,
          productId: p.productID,
          purchaseToken: p.verificationData.serverVerificationData,
        ),
      );
    }
  }

  BillingPurchaseStatus _mapStatus(PurchaseStatus status) {
    switch (status) {
      case PurchaseStatus.purchased:
        return BillingPurchaseStatus.success;
      case PurchaseStatus.restored:
        return BillingPurchaseStatus.restored;
      case PurchaseStatus.pending:
        return BillingPurchaseStatus.pending;
      case PurchaseStatus.error:
        return BillingPurchaseStatus.failed;
      case PurchaseStatus.canceled:
        return BillingPurchaseStatus.cancelled;
    }
  }

  @override
  Future<List<BillingProduct>> loadProducts() async {
    final iap = _iap;
    if (iap == null) return const [];
    try {
      final response = await iap.queryProductDetails(
        {monthlyProductId, yearlyProductId},
      );
      if (response.productDetails.isEmpty) return const [];
      return response.productDetails
          .map(
            (p) => BillingProduct(
              productId: p.id,
              title: p.title,
              description: p.description,
              price: p.price,
              rawPrice: p.rawPrice,
            ),
          )
          .toList();
    } on Object catch (_) {
      return const [];
    }
  }

  @override
  Future<BillingPurchaseResult> purchase({
    required BillingProduct product,
    required String userId,
  }) async {
    final iap = _iap;
    if (iap == null) {
      return const BillingPurchaseResult(
        status: BillingPurchaseStatus.failed,
        message: 'Billing unavailable on this device.',
      );
    }
    try {
      final response = await iap.buyNonConsumable(
        purchaseParam: PurchaseParam(
          productDetails: _toProductDetails(product),
        ),
      );
      if (!response) {
        return const BillingPurchaseResult(
          status: BillingPurchaseStatus.failed,
          message: 'Purchase did not start.',
        );
      }
      // Actual outcome arrives through `purchaseStream` → `_onPurchaseUpdate`,
      // which feeds `updates` and ultimately the SubscriptionBloc.
      return BillingPurchaseResult(
        status: BillingPurchaseStatus.pending,
        productId: product.productId,
      );
    } on Object catch (_) {
      return const BillingPurchaseResult(
        status: BillingPurchaseStatus.failed,
        message: 'Purchase failed.',
      );
    }
  }

  @override
  Future<BillingPurchaseResult> restore({required String userId}) async {
    final iap = _iap;
    if (iap == null) {
      return const BillingPurchaseResult(
        status: BillingPurchaseStatus.failed,
        message: 'Billing unavailable on this device.',
      );
    }
    try {
      await iap.restorePurchases();
      return const BillingPurchaseResult(
        status: BillingPurchaseStatus.restored,
      );
    } on Object catch (_) {
      return const BillingPurchaseResult(
        status: BillingPurchaseStatus.failed,
      );
    }
  }

  ProductDetails _toProductDetails(BillingProduct product) {
    // We construct a minimal ProductDetails; the real fields are only
    // needed when re-rendering the purchase dialog, which the platform
    // SDK drives itself.
    return ProductDetails(
      id: product.productId,
      title: product.title,
      description: product.description,
      price: product.price,
      rawPrice: product.rawPrice,
      currencyCode: '',
    );
  }
}
