/// Represents the available subscription tiers.
enum SubscriptionTier { free, monthly, yearly }

/// Model representing a subscription plan with pricing and metadata.
class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final SubscriptionTier tier;
  final String? storeProductId;
  final String currencySymbol;
  final List<String> features;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.tier,
    this.storeProductId,
    this.currencySymbol = '\$',
    this.features = const [],
  });

  String get formattedPrice {
    if (tier == SubscriptionTier.free) return 'Free';
    return '$currencySymbol${price.toStringAsFixed(2)}';
  }

  String get billingPeriod {
    switch (tier) {
      case SubscriptionTier.free:
        return '';
      case SubscriptionTier.monthly:
        return '/month';
      case SubscriptionTier.yearly:
        return '/year';
    }
  }

  double get monthlyEquivalent {
    if (tier == SubscriptionTier.yearly) return price / 12;
    return price;
  }

  int get savingsPercent {
    if (tier != SubscriptionTier.yearly) return 0;
    const monthlyPrice = 9.99;
    final yearlyMonthly = monthlyEquivalent;
    return ((1 - yearlyMonthly / monthlyPrice) * 100).round();
  }

  static const List<SubscriptionPlan> defaultPlans = [
    SubscriptionPlan(
      id: 'free',
      name: 'Free',
      description: 'Basic access with limited features',
      price: 0,
      tier: SubscriptionTier.free,
      features: [
        'Basic content access',
        'Limited to 5 items per day',
        'Community support',
      ],
    ),
    SubscriptionPlan(
      id: 'monthly_premium',
      name: 'Premium Monthly',
      description: 'Full access, billed monthly',
      price: 9.99,
      tier: SubscriptionTier.monthly,
      storeProductId: 'com.tranthienhau.flutter_iap_stripe.monthly',
      features: [
        'Unlimited content access',
        'No ads',
        'Priority support',
        'Offline downloads',
        'Advanced analytics',
      ],
    ),
    SubscriptionPlan(
      id: 'yearly_premium',
      name: 'Premium Yearly',
      description: 'Full access, billed annually - best value',
      price: 79.99,
      tier: SubscriptionTier.yearly,
      storeProductId: 'com.tranthienhau.flutter_iap_stripe.yearly',
      features: [
        'Everything in Monthly',
        'Save 33% vs monthly',
        'Exclusive yearly content',
        'Early access to new features',
        'Premium badge',
      ],
    ),
  ];

  SubscriptionPlan copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    SubscriptionTier? tier,
    String? storeProductId,
    String? currencySymbol,
    List<String>? features,
  }) {
    return SubscriptionPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      tier: tier ?? this.tier,
      storeProductId: storeProductId ?? this.storeProductId,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      features: features ?? this.features,
    );
  }
}
