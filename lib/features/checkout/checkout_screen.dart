import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/payment_method.dart';
import '../../models/purchase_record.dart';
import '../../models/subscription_plan.dart';
import '../paywall/paywall_provider.dart';
import 'stripe_checkout_screen.dart';

/// Checkout screen allowing the user to pick a payment method
/// (IAP, Apple Pay, Google Pay, or Stripe) and complete the purchase.
class CheckoutScreen extends ConsumerStatefulWidget {
  final SubscriptionPlan plan;

  const CheckoutScreen({super.key, required this.plan});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  PaymentMethodType? _selectedMethod;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Default to platform IAP
    if (Platform.isIOS) {
      _selectedMethod = PaymentMethodType.appleIap;
    } else {
      _selectedMethod = PaymentMethodType.googlePlay;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout'), elevation: 0),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildOrderSummary(),
                const SizedBox(height: 24),
                _buildPaymentMethods(),
              ],
            ),
          ),
          _buildPurchaseButton(),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.plan.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.plan.description,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Text(
                '${widget.plan.formattedPrice}${widget.plan.billingPeriod}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6C63FF),
                ),
              ),
            ],
          ),
          if (widget.plan.savingsPercent > 0) ...[
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('You save', style: TextStyle(color: Colors.green[700])),
                Text(
                  '${widget.plan.savingsPercent}% vs monthly',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    final methods = _getAvailableMethods();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        RadioGroup<PaymentMethodType>(
          groupValue: _selectedMethod ?? methods.first.type,
          onChanged: (value) {
            if (value != null) setState(() => _selectedMethod = value);
          },
          child: Column(
            children: methods
                .map((method) => _buildMethodTile(method))
                .toList(),
          ),
        ),
      ],
    );
  }

  List<PaymentMethod> _getAvailableMethods() {
    final methods = <PaymentMethod>[];

    if (Platform.isIOS) {
      methods.add(
        const PaymentMethod(
          type: PaymentMethodType.appleIap,
          label: 'Apple In-App Purchase',
          icon: 'apple',
        ),
      );
      methods.add(
        const PaymentMethod(
          type: PaymentMethodType.applePay,
          label: 'Apple Pay',
          icon: 'apple',
        ),
      );
    } else {
      methods.add(
        const PaymentMethod(
          type: PaymentMethodType.googlePlay,
          label: 'Google Play Billing',
          icon: 'shop',
        ),
      );
      methods.add(
        const PaymentMethod(
          type: PaymentMethodType.googlePay,
          label: 'Google Pay',
          icon: 'g_mobiledata',
        ),
      );
    }

    methods.add(
      const PaymentMethod(
        type: PaymentMethodType.stripe,
        label: 'Credit / Debit Card (Stripe)',
        icon: 'credit_card',
      ),
    );

    return methods;
  }

  Widget _buildMethodTile(PaymentMethod method) {
    final isSelected = _selectedMethod == method.type;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF6C63FF) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: ListTile(
          onTap: () => setState(() => _selectedMethod = method.type),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: Radio<PaymentMethodType>(value: method.type),
          title: Row(
            children: [
              Icon(
                _getIconData(method.icon),
                color: isSelected ? const Color(0xFF6C63FF) : Colors.grey[600],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  method.label,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String icon) {
    switch (icon) {
      case 'apple':
        return Icons.apple;
      case 'shop':
        return Icons.shop;
      case 'g_mobiledata':
        return Icons.g_mobiledata;
      case 'credit_card':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  Widget _buildPurchaseButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _handlePurchase,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Pay ${widget.plan.formattedPrice}${widget.plan.billingPeriod}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePurchase() async {
    if (_selectedMethod == null) return;

    setState(() => _isProcessing = true);

    try {
      switch (_selectedMethod!) {
        case PaymentMethodType.appleIap:
        case PaymentMethodType.googlePlay:
          await _handleIapPurchase();
          break;
        case PaymentMethodType.applePay:
        case PaymentMethodType.googlePay:
          await _handleNativePayPurchase();
          break;
        case PaymentMethodType.stripe:
          await _handleStripePurchase();
          break;
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleIapPurchase() async {
    final notifier = ref.read(paywallProvider.notifier);
    await notifier.purchasePlan(widget.plan);

    if (mounted) {
      final state = ref.read(paywallProvider);
      if (state.activeTier == widget.plan.tier) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handleNativePayPurchase() async {
    final source = _selectedMethod == PaymentMethodType.applePay
        ? PurchaseSource.applePay
        : PurchaseSource.googlePay;

    // Simulate native pay for demo
    await Future.delayed(const Duration(seconds: 1));

    final record = PurchaseRecord(
      id: 'native_${DateTime.now().millisecondsSinceEpoch}',
      productId: widget.plan.storeProductId ?? widget.plan.id,
      productName: widget.plan.name,
      amount: widget.plan.price,
      source: source,
      status: PurchaseStatus.completed,
      purchaseDate: DateTime.now(),
      expiryDate: widget.plan.tier == SubscriptionTier.monthly
          ? DateTime.now().add(const Duration(days: 30))
          : DateTime.now().add(const Duration(days: 365)),
      transactionId: 'native_txn_${DateTime.now().millisecondsSinceEpoch}',
    );

    final manager = ref.read(subscriptionManagerProvider);
    await manager.activateSubscription(record: record, tier: widget.plan.tier);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${source == PurchaseSource.applePay ? "Apple" : "Google"} Pay payment successful!',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleStripePurchase() async {
    if (!mounted) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => StripeCheckoutScreen(plan: widget.plan),
      ),
    );

    if (result == true && mounted) {
      Navigator.of(context).pop();
    }
  }
}
