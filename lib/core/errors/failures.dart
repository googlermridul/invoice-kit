import 'package:equatable/equatable.dart';

/// Base Failure contract — every domain-layer failure extends this.
abstract class Failure extends Equatable {
  const Failure({
    this.message = 'Unexpected error',
    this.code,
    this.stackTrace,
  });

  final String message;
  final String? code;
  final StackTrace? stackTrace;

  @override
  List<Object?> get props => [message, code];
}

/// No internet connectivity.
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection.',
    super.code = 'NETWORK_FAILURE',
  });
}

/// Server returned 5xx or any unrecoverable backend error.
class ServerFailure extends Failure {
  const ServerFailure({
    super.message = 'Server error. Please try again later.',
    super.code = 'SERVER_FAILURE',
  });
}

/// Generic API failure (4xx other than 401).
class ApiFailure extends Failure {
  const ApiFailure({required super.message, super.code = 'API_FAILURE'});
}

/// Unauthorized (401). Trigger logout/refresh.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    super.message = 'Session expired. Please log in again.',
    super.code = 'UNAUTHORIZED',
  });
}

/// Validation errors (422 / form-level).
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    this.fields = const {},
    super.code = 'VALIDATION_FAILURE',
  });

  final Map<String, String> fields;

  @override
  List<Object?> get props => [...super.props, fields];
}

/// Cached / local storage failure.
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Local cache failure.',
    super.code = 'CACHE_FAILURE',
  });
}

/// Unknown / uncategorised failure.
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unknown error occurred.',
    super.code = 'UNKNOWN_FAILURE',
  });
}

/// Invalid auth credentials (400/401 from auth endpoint).
class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure({
    super.message = 'Invalid email or password.',
    super.code = 'INVALID_CREDENTIALS',
  });
}

/// Local storage read/write failure.
class StorageFailure extends Failure {
  const StorageFailure({
    super.message = 'Local storage error.',
    super.code = 'STORAGE_FAILURE',
  });
}

/// Google Play Billing not available (store missing / unavailable).
class BillingUnavailableFailure extends Failure {
  const BillingUnavailableFailure({
    super.message = 'Billing is currently unavailable on this device.',
    super.code = 'BILLING_UNAVAILABLE',
  });
}

/// User cancelled the in-app purchase.
class PurchaseCancelledFailure extends Failure {
  const PurchaseCancelledFailure({
    super.message = 'Purchase cancelled.',
    super.code = 'PURCHASE_CANCELLED',
  });
}

/// Purchase pending (awaiting confirmation / payment method).
class PurchasePendingFailure extends Failure {
  const PurchasePendingFailure({
    super.message = 'Purchase is pending.',
    super.code = 'PURCHASE_PENDING',
  });
}

/// Server-side purchase verification failed.
class PurchaseVerificationFailure extends Failure {
  const PurchaseVerificationFailure({
    super.message = 'Purchase could not be verified.',
    super.code = 'PURCHASE_VERIFICATION_FAILED',
  });
}

/// Subscription has expired.
class SubscriptionExpiredFailure extends Failure {
  const SubscriptionExpiredFailure({
    super.message = 'Subscription expired.',
    super.code = 'SUBSCRIPTION_EXPIRED',
  });
}

/// Device limit exceeded for the current account.
class DeviceLimitFailure extends Failure {
  const DeviceLimitFailure({
    super.message = 'Maximum number of devices reached.',
    super.code = 'DEVICE_LIMIT_EXCEEDED',
  });
}

/// Auth session has expired or is missing.
class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure({
    super.message = 'Session expired.',
    super.code = 'SESSION_EXPIRED',
  });
}
