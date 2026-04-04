/// Supported payment method types.
enum PaymentMethodType { appleIap, googlePlay, stripe, applePay, googlePay }

/// Model representing a payment method available to the user.
class PaymentMethod {
  final PaymentMethodType type;
  final String label;
  final String icon;
  final bool isAvailable;
  final String? lastFourDigits;

  const PaymentMethod({
    required this.type,
    required this.label,
    required this.icon,
    this.isAvailable = true,
    this.lastFourDigits,
  });

  String get displayName {
    if (lastFourDigits != null) {
      return '$label (*$lastFourDigits)';
    }
    return label;
  }

  static const List<PaymentMethod> allMethods = [
    PaymentMethod(
      type: PaymentMethodType.appleIap,
      label: 'Apple In-App Purchase',
      icon: 'apple',
    ),
    PaymentMethod(
      type: PaymentMethodType.googlePlay,
      label: 'Google Play Billing',
      icon: 'shop',
    ),
    PaymentMethod(
      type: PaymentMethodType.applePay,
      label: 'Apple Pay',
      icon: 'apple',
    ),
    PaymentMethod(
      type: PaymentMethodType.googlePay,
      label: 'Google Pay',
      icon: 'g_mobiledata',
    ),
    PaymentMethod(
      type: PaymentMethodType.stripe,
      label: 'Credit / Debit Card',
      icon: 'credit_card',
    ),
  ];
}
