import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// The result of a receipt validation request.
class ValidationResult {
  final bool isValid;
  final String? productId;
  final DateTime? expiryDate;
  final String? originalTransactionId;
  final String? errorMessage;
  final Map<String, dynamic>? rawResponse;

  const ValidationResult({
    required this.isValid,
    this.productId,
    this.expiryDate,
    this.originalTransactionId,
    this.errorMessage,
    this.rawResponse,
  });
}

/// Service responsible for validating purchase receipts with
/// Apple's verifyReceipt endpoint and Google Play Developer API.
///
/// In production, receipt validation MUST happen server-side
/// to prevent spoofing. This service demonstrates the flow.
class ReceiptValidator {
  final String? backendUrl;

  ReceiptValidator({this.backendUrl});

  /// Validate an Apple App Store receipt.
  ///
  /// In production, the receipt data should be sent to your backend,
  /// which then communicates with Apple's verifyReceipt endpoint.
  /// Never call Apple's endpoint directly from the client.
  Future<ValidationResult> validateAppleReceipt(String receiptData) async {
    debugPrint('[ReceiptValidator] Validating Apple receipt...');

    if (backendUrl != null) {
      return _validateViaBackend(receiptData: receiptData, platform: 'apple');
    }

    // Simulated validation for POC demo
    return _simulateAppleValidation(receiptData);
  }

  /// Validate a Google Play purchase token.
  ///
  /// In production, send the purchase token to your backend,
  /// which verifies it using the Google Play Developer API.
  Future<ValidationResult> validateGoogleReceipt({
    required String purchaseToken,
    required String productId,
  }) async {
    debugPrint('[ReceiptValidator] Validating Google receipt...');

    if (backendUrl != null) {
      return _validateViaBackend(
        receiptData: purchaseToken,
        platform: 'google',
        productId: productId,
      );
    }

    // Simulated validation for POC demo
    return _simulateGoogleValidation(purchaseToken, productId);
  }

  /// Validate a Stripe payment via backend.
  Future<ValidationResult> validateStripePayment(String paymentIntentId) async {
    debugPrint('[ReceiptValidator] Validating Stripe payment...');

    if (backendUrl != null) {
      try {
        final response = await http.post(
          Uri.parse('$backendUrl/validate-stripe-payment'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'paymentIntentId': paymentIntentId}),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return ValidationResult(
            isValid: data['valid'] == true,
            productId: data['productId'] as String?,
            originalTransactionId: paymentIntentId,
            rawResponse: data,
          );
        }
      } catch (e) {
        debugPrint('[ReceiptValidator] Stripe validation error: $e');
      }
    }

    // Simulated for demo
    return ValidationResult(
      isValid: true,
      originalTransactionId: paymentIntentId,
    );
  }

  /// Send receipt to backend for server-side validation.
  Future<ValidationResult> _validateViaBackend({
    required String receiptData,
    required String platform,
    String? productId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/validate-receipt'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'receipt': receiptData,
          'platform': platform,
          'productId': productId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ValidationResult(
          isValid: data['valid'] == true,
          productId: data['productId'] as String?,
          expiryDate: data['expiryDate'] != null
              ? DateTime.parse(data['expiryDate'] as String)
              : null,
          originalTransactionId: data['transactionId'] as String?,
          rawResponse: data,
        );
      }

      return ValidationResult(
        isValid: false,
        errorMessage: 'Server returned ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('[ReceiptValidator] Backend validation error: $e');
      return ValidationResult(isValid: false, errorMessage: e.toString());
    }
  }

  /// Simulated Apple receipt validation for offline demo.
  ValidationResult _simulateAppleValidation(String receiptData) {
    debugPrint('[ReceiptValidator] Simulating Apple validation (demo mode)');
    return ValidationResult(
      isValid: true,
      productId: 'com.tranthienhau.flutter_iap_stripe.monthly',
      expiryDate: DateTime.now().add(const Duration(days: 30)),
      originalTransactionId:
          'apple_txn_${DateTime.now().millisecondsSinceEpoch}',
      rawResponse: {'status': 0, 'environment': 'Sandbox'},
    );
  }

  /// Simulated Google Play validation for offline demo.
  ValidationResult _simulateGoogleValidation(
    String purchaseToken,
    String productId,
  ) {
    debugPrint('[ReceiptValidator] Simulating Google validation (demo mode)');
    return ValidationResult(
      isValid: true,
      productId: productId,
      expiryDate: DateTime.now().add(const Duration(days: 30)),
      originalTransactionId:
          'google_txn_${DateTime.now().millisecondsSinceEpoch}',
      rawResponse: {'purchaseState': 0, 'acknowledgementState': 1},
    );
  }
}
