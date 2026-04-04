import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

/// Configuration for connecting to a Stripe backend.
class StripeConfig {
  /// Publishable key from the Stripe dashboard.
  final String publishableKey;

  /// Base URL for your backend that creates PaymentIntents.
  final String backendUrl;

  /// Merchant display name for the payment sheet.
  final String merchantDisplayName;

  const StripeConfig({
    required this.publishableKey,
    required this.backendUrl,
    this.merchantDisplayName = 'Flutter IAP Demo',
  });
}

/// Result of a Stripe payment attempt.
class StripePaymentResult {
  final bool success;
  final String? paymentIntentId;
  final String? errorMessage;

  const StripePaymentResult({
    required this.success,
    this.paymentIntentId,
    this.errorMessage,
  });
}

/// Service handling Stripe payment integration, including
/// PaymentSheet presentation and PaymentIntent creation.
class StripeService {
  final StripeConfig config;

  StripeService({required this.config});

  /// Initialize Stripe SDK with the publishable key.
  void initialize() {
    Stripe.publishableKey = config.publishableKey;
    Stripe.merchantIdentifier = 'merchant.com.tranthienhau.flutteriapstripe';
    debugPrint(
      '[StripeService] Initialized with key: ${config.publishableKey.substring(0, 12)}...',
    );
  }

  /// Create a PaymentIntent on your backend and return the client secret.
  ///
  /// In production, this calls your server which communicates with
  /// the Stripe API. For this POC, we simulate the response.
  Future<String?> createPaymentIntent({
    required int amountInCents,
    String currency = 'usd',
    Map<String, String>? metadata,
  }) async {
    try {
      // In production, call your backend:
      // POST /create-payment-intent
      // Body: { amount: amountInCents, currency: currency }
      //
      // The backend returns: { clientSecret: 'pi_xxx_secret_xxx' }

      final response = await http.post(
        Uri.parse('${config.backendUrl}/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amountInCents,
          'currency': currency,
          'metadata': metadata ?? {},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['clientSecret'] as String?;
      }

      debugPrint('[StripeService] Backend error: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('[StripeService] createPaymentIntent error: $e');
      // For POC demo, return a simulated secret
      return _simulatePaymentIntent(amountInCents, currency);
    }
  }

  /// Present the Stripe PaymentSheet for the user to complete payment.
  Future<StripePaymentResult> presentPaymentSheet({
    required int amountInCents,
    String currency = 'usd',
  }) async {
    try {
      final clientSecret = await createPaymentIntent(
        amountInCents: amountInCents,
        currency: currency,
      );

      if (clientSecret == null) {
        return const StripePaymentResult(
          success: false,
          errorMessage: 'Failed to create payment intent',
        );
      }

      // Initialize the payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: config.merchantDisplayName,
          style: ThemeMode.system,
          billingDetailsCollectionConfiguration:
              const BillingDetailsCollectionConfiguration(
                name: CollectionMode.automatic,
                email: CollectionMode.automatic,
              ),
        ),
      );

      // Present it
      await Stripe.instance.presentPaymentSheet();

      debugPrint('[StripeService] Payment sheet completed successfully');
      return StripePaymentResult(
        success: true,
        paymentIntentId: clientSecret.split('_secret_').first,
      );
    } on StripeException catch (e) {
      debugPrint(
        '[StripeService] StripeException: ${e.error.localizedMessage}',
      );
      return StripePaymentResult(
        success: false,
        errorMessage: e.error.localizedMessage ?? 'Payment cancelled',
      );
    } catch (e) {
      debugPrint('[StripeService] Payment error: $e');
      return StripePaymentResult(success: false, errorMessage: e.toString());
    }
  }

  /// Create a Stripe subscription via backend.
  Future<StripePaymentResult> createSubscription({
    required String priceId,
    required String customerEmail,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${config.backendUrl}/create-subscription'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'priceId': priceId, 'email': customerEmail}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final clientSecret = data['clientSecret'] as String?;

        if (clientSecret != null) {
          await Stripe.instance.initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
              paymentIntentClientSecret: clientSecret,
              merchantDisplayName: config.merchantDisplayName,
            ),
          );

          await Stripe.instance.presentPaymentSheet();

          return StripePaymentResult(
            success: true,
            paymentIntentId: data['subscriptionId'] as String?,
          );
        }
      }

      return const StripePaymentResult(
        success: false,
        errorMessage: 'Failed to create subscription',
      );
    } catch (e) {
      debugPrint('[StripeService] Subscription error: $e');
      return StripePaymentResult(success: false, errorMessage: e.toString());
    }
  }

  /// Simulate a payment intent for demo / offline testing.
  String? _simulatePaymentIntent(int amount, String currency) {
    debugPrint(
      '[StripeService] Simulating PaymentIntent: '
      '$amount $currency (demo mode)',
    );
    // Return null to trigger the demo flow in the UI
    return null;
  }
}
