import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/purchase_record.dart';
import '../../models/subscription_plan.dart';
import '../../services/subscription_manager.dart';
import '../paywall/paywall_provider.dart';

/// State for the subscription management screen.
class SubscriptionState {
  final SubscriptionTier activeTier;
  final PurchaseRecord? activeSubscription;
  final bool isLoading;
  final String? message;

  const SubscriptionState({
    this.activeTier = SubscriptionTier.free,
    this.activeSubscription,
    this.isLoading = true,
    this.message,
  });

  SubscriptionState copyWith({
    SubscriptionTier? activeTier,
    PurchaseRecord? activeSubscription,
    bool? isLoading,
    String? message,
  }) {
    return SubscriptionState(
      activeTier: activeTier ?? this.activeTier,
      activeSubscription: activeSubscription ?? this.activeSubscription,
      isLoading: isLoading ?? this.isLoading,
      message: message,
    );
  }
}

/// Provider for subscription management.
final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
      return SubscriptionNotifier(
        subscriptionManager: ref.watch(subscriptionManagerProvider),
      );
    });

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final SubscriptionManager subscriptionManager;

  SubscriptionNotifier({required this.subscriptionManager})
    : super(const SubscriptionState()) {
    loadSubscription();
  }

  Future<void> loadSubscription() async {
    state = state.copyWith(isLoading: true);

    final tier = await subscriptionManager.getActiveTier();
    final activeSub = await subscriptionManager.getActiveSubscription();

    state = state.copyWith(
      activeTier: tier,
      activeSubscription: activeSub,
      isLoading: false,
    );
  }

  Future<void> cancelSubscription() async {
    await subscriptionManager.cancelSubscription();
    state = SubscriptionState(
      activeTier: SubscriptionTier.free,
      isLoading: false,
      message: 'Subscription cancelled. You can continue using free features.',
    );
  }

  void clearMessage() {
    state = state.copyWith(message: null);
  }
}
