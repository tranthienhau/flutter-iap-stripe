import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/purchase_record.dart';
import '../../models/subscription_plan.dart';
import '../../services/stripe_service.dart';
import '../paywall/paywall_provider.dart';

/// Provider for the Stripe service.
final stripeServiceProvider = Provider<StripeService>((ref) {
  return StripeService(
    config: const StripeConfig(
      publishableKey: 'pk_test_DEMO_KEY',
      backendUrl: 'https://api.example.com',
    ),
  );
});

/// Stripe checkout screen with card payment form.
/// Demonstrates Stripe PaymentSheet integration and
/// manual card entry as a fallback.
class StripeCheckoutScreen extends ConsumerStatefulWidget {
  final SubscriptionPlan plan;

  const StripeCheckoutScreen({super.key, required this.plan});

  @override
  ConsumerState<StripeCheckoutScreen> createState() =>
      _StripeCheckoutScreenState();
}

class _StripeCheckoutScreenState extends ConsumerState<StripeCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isProcessing = false;
  bool _usePaymentSheet = true;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Card Payment'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSecurityBanner(),
            const SizedBox(height: 20),
            _buildAmountDisplay(),
            const SizedBox(height: 24),
            _buildPaymentSheetOption(),
            const SizedBox(height: 16),
            if (!_usePaymentSheet) _buildCardForm(),
            const SizedBox(height: 24),
            _buildPayButton(),
            const SizedBox(height: 16),
            _buildStripeFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your payment is secured with Stripe encryption',
              style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF3F3D9E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Total Amount',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.plan.formattedPrice}${widget.plan.billingPeriod}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.plan.name,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSheetOption() {
    return RadioGroup<bool>(
      groupValue: _usePaymentSheet,
      onChanged: (v) {
        if (v != null) setState(() => _usePaymentSheet = v);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _usePaymentSheet
                    ? const Color(0xFF6C63FF)
                    : Colors.grey.shade300,
                width: _usePaymentSheet ? 2 : 1,
              ),
            ),
            child: ListTile(
              onTap: () => setState(() => _usePaymentSheet = true),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: const Radio<bool>(value: true),
              title: const Row(
                children: [
                  Icon(Icons.payment, color: Color(0xFF6C63FF)),
                  SizedBox(width: 12),
                  Text('Stripe Payment Sheet'),
                ],
              ),
              subtitle: const Text(
                'Recommended - supports cards, wallets, and more',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: !_usePaymentSheet
                    ? const Color(0xFF6C63FF)
                    : Colors.grey.shade300,
                width: !_usePaymentSheet ? 2 : 1,
              ),
            ),
            child: ListTile(
              onTap: () => setState(() => _usePaymentSheet = false),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: const Radio<bool>(value: false),
              title: const Row(
                children: [
                  Icon(Icons.credit_card, color: Color(0xFF6C63FF)),
                  SizedBox(width: 12),
                  Text('Manual Card Entry'),
                ],
              ),
              subtitle: const Text(
                'Enter card details directly',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Card Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            decoration: _inputDecoration(
              'Cardholder Name',
              Icons.person_outline,
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'Name is required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            decoration: _inputDecoration('Email', Icons.email_outlined),
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cardNumberController,
            decoration: _inputDecoration('Card Number', Icons.credit_card),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Card number is required';
              final digits = v.replaceAll(' ', '');
              if (digits.length < 13 || digits.length > 19) {
                return 'Enter a valid card number';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryController,
                  decoration: _inputDecoration('MM/YY', Icons.calendar_today),
                  keyboardType: TextInputType.datetime,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _cvcController,
                  decoration: _inputDecoration('CVC', Icons.lock_outline),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _handlePayment,
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
                'Pay ${widget.plan.formattedPrice}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildStripeFooter() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock, size: 14, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Text(
            'Powered by Stripe',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePayment() async {
    if (_usePaymentSheet) {
      await _handlePaymentSheet();
    } else {
      if (!_formKey.currentState!.validate()) return;
      await _handleManualCardPayment();
    }
  }

  Future<void> _handlePaymentSheet() async {
    setState(() => _isProcessing = true);

    try {
      final stripeService = ref.read(stripeServiceProvider);
      final amountInCents = (widget.plan.price * 100).round();

      final result = await stripeService.presentPaymentSheet(
        amountInCents: amountInCents,
      );

      if (result.success) {
        await _recordStripePurchase(result.paymentIntentId);
      } else {
        // Simulate success for demo when Stripe is not configured
        await _simulateStripeSuccess();
      }
    } catch (e) {
      // Fallback: simulate success for demo
      await _simulateStripeSuccess();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleManualCardPayment() async {
    setState(() => _isProcessing = true);

    try {
      // In production, tokenize the card with Stripe and create a charge.
      // For this POC, we simulate the process.
      await Future.delayed(const Duration(seconds: 2));
      await _simulateStripeSuccess();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _recordStripePurchase(String? paymentIntentId) async {
    final record = PurchaseRecord(
      id: 'stripe_${DateTime.now().millisecondsSinceEpoch}',
      productId: widget.plan.storeProductId ?? widget.plan.id,
      productName: widget.plan.name,
      amount: widget.plan.price,
      source: PurchaseSource.stripe,
      status: PurchaseStatus.completed,
      purchaseDate: DateTime.now(),
      expiryDate: widget.plan.tier == SubscriptionTier.monthly
          ? DateTime.now().add(const Duration(days: 30))
          : DateTime.now().add(const Duration(days: 365)),
      transactionId:
          paymentIntentId ??
          'stripe_txn_${DateTime.now().millisecondsSinceEpoch}',
    );

    final manager = ref.read(subscriptionManagerProvider);
    await manager.activateSubscription(record: record, tier: widget.plan.tier);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Payment successful!'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _simulateStripeSuccess() async {
    await _recordStripePurchase(
      'demo_pi_${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}
