import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/purchase_record.dart';
import '../../models/subscription_plan.dart';
import '../../services/iap_service.dart';
import '../../services/receipt_validator.dart';
import '../../services/subscription_manager.dart';

/// State for the paywall screen.
class PaywallState {
  final List<SubscriptionPlan> plans;
  final SubscriptionTier activeTier;
  final bool isLoading;
  final bool isPurchasing;
  final String? errorMessage;
  final String? successMessage;

  const PaywallState({
    this.plans = const [],
    this.activeTier = SubscriptionTier.free,
    this.isLoading = true,
    this.isPurchasing = false,
    this.errorMessage,
    this.successMessage,
  });

  PaywallState copyWith({
    List<SubscriptionPlan>? plans,
    SubscriptionTier? activeTier,
    bool? isLoading,
    bool? isPurchasing,
    String? errorMessage,
    String? successMessage,
  }) {
    return PaywallState(
      plans: plans ?? this.plans,
      activeTier: activeTier ?? this.activeTier,
      isLoading: isLoading ?? this.isLoading,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

/// Provider for IAP service instance.
final iapServiceProvider = Provider<IapService>((ref) {
  final service = IapService();
  ref.onDispose(service.dispose);
  return service;
});

/// Provider for receipt validator instance.
final receiptValidatorProvider = Provider<ReceiptValidator>((ref) {
  return ReceiptValidator();
});

/// Provider for subscription manager instance.
final subscriptionManagerProvider = Provider<SubscriptionManager>((ref) {
  return SubscriptionManager();
});

/// Main paywall state notifier.
final paywallProvider = StateNotifierProvider<PaywallNotifier, PaywallState>((
  ref,
) {
  return PaywallNotifier(
    iapService: ref.watch(iapServiceProvider),
    receiptValidator: ref.watch(receiptValidatorProvider),
    subscriptionManager: ref.watch(subscriptionManagerProvider),
  );
});

class PaywallNotifier extends StateNotifier<PaywallState> {
  final IapService iapService;
  final ReceiptValidator receiptValidator;
  final SubscriptionManager subscriptionManager;

  PaywallNotifier({
    required this.iapService,
    required this.receiptValidator,
    required this.subscriptionManager,
  }) : super(const PaywallState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    await iapService.initialize();
    final tier = await subscriptionManager.getActiveTier();

    state = state.copyWith(
      plans: SubscriptionPlan.defaultPlans,
      activeTier: tier,
      isLoading: false,
    );

    // Listen for IAP purchase updates
    iapService.purchaseStream.listen(_handlePurchaseUpdates);
  }

  void _handlePurchaseUpdates(List<dynamic> purchases) {
    // Process IAP purchase updates from the store
    for (final _ in purchases) {
      // In a real app, inspect purchase.status and handle accordingly
      state = state.copyWith(isPurchasing: false);
    }
  }

  /// Initiate an in-app purchase for the given plan.
  Future<void> purchasePlan(SubscriptionPlan plan) async {
    if (plan.tier == SubscriptionTier.free) return;

    state = state.copyWith(isPurchasing: true, errorMessage: null);

    try {
      final products = await iapService.queryProducts();
      final product = products.where((p) => p.id == plan.storeProductId);

      if (product.isEmpty) {
        // Simulate purchase for demo when store products are not configured
        await _simulatePurchase(plan);
        return;
      }

      await iapService.purchaseSubscription(product.first);
    } catch (e) {
      state = state.copyWith(
        isPurchasing: false,
        errorMessage: 'Purchase failed: $e',
      );
    }
  }

  /// Simulate a successful purchase for demo purposes.
  Future<void> _simulatePurchase(SubscriptionPlan plan) async {
    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 1));

    final record = PurchaseRecord(
      id: 'demo_${DateTime.now().millisecondsSinceEpoch}',
      productId: plan.storeProductId ?? plan.id,
      productName: plan.name,
      amount: plan.price,
      source: PurchaseSource.appleIap,
      status: PurchaseStatus.completed,
      purchaseDate: DateTime.now(),
      expiryDate: plan.tier == SubscriptionTier.monthly
          ? DateTime.now().add(const Duration(days: 30))
          : DateTime.now().add(const Duration(days: 365)),
      transactionId: 'demo_txn_${DateTime.now().millisecondsSinceEpoch}',
    );

    await subscriptionManager.activateSubscription(
      record: record,
      tier: plan.tier,
    );

    state = state.copyWith(
      activeTier: plan.tier,
      isPurchasing: false,
      successMessage: 'Successfully subscribed to ${plan.name}!',
    );
  }

  /// Restore previous purchases.
  Future<void> restorePurchases() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await iapService.restorePurchases();

      // Check subscription manager for restored state
      final tier = await subscriptionManager.getActiveTier();
      state = state.copyWith(
        activeTier: tier,
        isLoading: false,
        successMessage: tier != SubscriptionTier.free
            ? 'Purchases restored successfully!'
            : 'No previous purchases found.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Restore failed: $e',
      );
    }
  }

  /// Clear messages after display.
  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}
