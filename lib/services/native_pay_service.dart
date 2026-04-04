import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:pay/pay.dart';

/// Result of a native pay (Apple Pay / Google Pay) attempt.
class NativePayResult {
  final bool success;
  final String? token;
  final String? errorMessage;

  const NativePayResult({required this.success, this.token, this.errorMessage});
}

/// Service that handles Apple Pay and Google Pay via the `pay` plugin.
class NativePayService {
  Pay? _payClient;

  /// Apple Pay merchant ID.
  static const String appleMerchantId =
      'merchant.com.tranthienhau.flutteriapstripe';

  /// Whether Apple Pay is available on this device.
  Future<bool> isApplePayAvailable() async {
    if (!Platform.isIOS) return false;
    try {
      _payClient ??= Pay({
        PayProvider.apple_pay: PaymentConfiguration.fromJsonString(
          _applePayConfig,
        ),
      });
      return await _payClient!.userCanPay(PayProvider.apple_pay);
    } catch (e) {
      debugPrint('[NativePayService] Apple Pay check error: $e');
      return false;
    }
  }

  /// Whether Google Pay is available on this device.
  Future<bool> isGooglePayAvailable() async {
    if (!Platform.isAndroid) return false;
    try {
      _payClient ??= Pay({
        PayProvider.google_pay: PaymentConfiguration.fromJsonString(
          _googlePayConfig,
        ),
      });
      return await _payClient!.userCanPay(PayProvider.google_pay);
    } catch (e) {
      debugPrint('[NativePayService] Google Pay check error: $e');
      return false;
    }
  }

  /// Start an Apple Pay payment session.
  Future<NativePayResult> payWithApplePay({
    required double amount,
    required String label,
    String currencyCode = 'USD',
    String countryCode = 'US',
  }) async {
    try {
      _payClient ??= Pay({
        PayProvider.apple_pay: PaymentConfiguration.fromJsonString(
          _applePayConfig,
        ),
      });

      final paymentItems = [
        PaymentItem(
          label: label,
          amount: amount.toStringAsFixed(2),
          status: PaymentItemStatus.final_price,
        ),
      ];

      final result = await _payClient!.showPaymentSelector(
        PayProvider.apple_pay,
        paymentItems,
      );

      debugPrint('[NativePayService] Apple Pay success: $result');
      return NativePayResult(success: true, token: result.toString());
    } catch (e) {
      debugPrint('[NativePayService] Apple Pay error: $e');
      return NativePayResult(success: false, errorMessage: e.toString());
    }
  }

  /// Start a Google Pay payment session.
  Future<NativePayResult> payWithGooglePay({
    required double amount,
    required String label,
    String currencyCode = 'USD',
    String countryCode = 'US',
  }) async {
    try {
      _payClient ??= Pay({
        PayProvider.google_pay: PaymentConfiguration.fromJsonString(
          _googlePayConfig,
        ),
      });

      final paymentItems = [
        PaymentItem(
          label: label,
          amount: amount.toStringAsFixed(2),
          status: PaymentItemStatus.final_price,
        ),
      ];

      final result = await _payClient!.showPaymentSelector(
        PayProvider.google_pay,
        paymentItems,
      );

      debugPrint('[NativePayService] Google Pay success: $result');
      return NativePayResult(success: true, token: result.toString());
    } catch (e) {
      debugPrint('[NativePayService] Google Pay error: $e');
      return NativePayResult(success: false, errorMessage: e.toString());
    }
  }

  /// Apple Pay configuration JSON.
  static const String _applePayConfig =
      '''
{
  "provider": "apple_pay",
  "data": {
    "merchantIdentifier": "$appleMerchantId",
    "displayName": "Flutter IAP Demo",
    "merchantCapabilities": ["3DS", "debit", "credit"],
    "supportedNetworks": ["amex", "visa", "discover", "masterCard"],
    "countryCode": "US",
    "currencyCode": "USD"
  }
}
''';

  /// Google Pay configuration JSON.
  static const String _googlePayConfig = '''
{
  "provider": "google_pay",
  "data": {
    "environment": "TEST",
    "apiVersion": 2,
    "apiVersionMinor": 0,
    "allowedPaymentMethods": [
      {
        "type": "CARD",
        "tokenizationSpecification": {
          "type": "PAYMENT_GATEWAY",
          "parameters": {
            "gateway": "stripe",
            "stripe:version": "2020-08-27",
            "stripe:publishableKey": "pk_test_demo"
          }
        },
        "parameters": {
          "allowedCardNetworks": ["VISA", "MASTERCARD", "AMEX", "DISCOVER"],
          "allowedAuthMethods": ["PAN_ONLY", "CRYPTOGRAM_3DS"],
          "billingAddressRequired": true
        }
      }
    ],
    "merchantInfo": {
      "merchantId": "BCR2DN4T6EXAMPLE",
      "merchantName": "Flutter IAP Demo"
    },
    "transactionInfo": {
      "countryCode": "US",
      "currencyCode": "USD"
    }
  }
}
''';
}
