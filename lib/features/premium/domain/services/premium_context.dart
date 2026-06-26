import 'package:equatable/equatable.dart';
import 'package:invoice_kit/features/subscription/domain/entities/subscription_status.dart';

/// Inputs the centralised access manager needs to make a decision.
class PremiumContext extends Equatable {
  const PremiumContext({
    required this.status,
    required this.isAuthenticated,
    this.deviceCount = 0,
    this.maxDevices = 3,
    this.now,
  });

  factory PremiumContext.now({
    required SubscriptionStatus status,
    required bool isAuthenticated,
    int deviceCount = 0,
    int maxDevices = 3,
  }) => PremiumContext(
    status: status,
    isAuthenticated: isAuthenticated,
    deviceCount: deviceCount,
    maxDevices: maxDevices,
    now: DateTime.now(),
  );

  final SubscriptionStatus status;
  final bool isAuthenticated;
  final int deviceCount;
  final int maxDevices;
  final DateTime? now;

  DateTime effectiveNow() => now ?? DateTime.now();

  @override
  List<Object?> get props => [
    status,
    isAuthenticated,
    deviceCount,
    maxDevices,
    now,
  ];
}
