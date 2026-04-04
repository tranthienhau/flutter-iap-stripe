import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Service that wraps the in_app_purchase plugin for managing
/// Apple IAP subscriptions and Google Play Billing.
class IapService {
  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final _purchaseController =
      StreamController<List<PurchaseDetails>>.broadcast();

  /// Stream of purchase updates from the store.
  Stream<List<PurchaseDetails>> get purchaseStream =>
      _purchaseController.stream;

  /// Product IDs for available subscriptions.
  static const Set<String> subscriptionIds = {
    'com.tranthienhau.flutter_iap_stripe.monthly',
    'com.tranthienhau.flutter_iap_stripe.yearly',
  };

  /// Initialize the IAP service and start listening for purchase updates.
  Future<void> initialize() async {
    final available = await _iap.isAvailable();
    if (!available) {
      debugPrint('[IapService] Store is not available');
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdated,
      onError: (error) {
        debugPrint('[IapService] Purchase stream error: $error');
      },
      onDone: () {
        debugPrint('[IapService] Purchase stream closed');
      },
    );

    debugPrint('[IapService] Initialized successfully');
  }

  /// Query available products from the store.
  Future<List<ProductDetails>> queryProducts() async {
    final available = await _iap.isAvailable();
    if (!available) return [];

    final response = await _iap.queryProductDetails(subscriptionIds);

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('[IapService] Products not found: ${response.notFoundIDs}');
    }

    if (response.error != null) {
      debugPrint('[IapService] Query error: ${response.error}');
      return [];
    }

    debugPrint('[IapService] Found ${response.productDetails.length} products');
    return response.productDetails;
  }

  /// Initiate a subscription purchase.
  Future<bool> purchaseSubscription(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);

    try {
      final success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      debugPrint('[IapService] Purchase initiated: $success');
      return success;
    } catch (e) {
      debugPrint('[IapService] Purchase error: $e');
      return false;
    }
  }

  /// Restore previous purchases (e.g., after reinstall or device switch).
  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
      debugPrint('[IapService] Restore purchases requested');
    } catch (e) {
      debugPrint('[IapService] Restore error: $e');
    }
  }

  /// Complete a pending purchase to finalize the transaction.
  Future<void> completePurchase(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
      debugPrint('[IapService] Purchase completed: ${purchase.productID}');
    }
  }

  void _onPurchaseUpdated(List<PurchaseDetails> purchases) {
    _purchaseController.add(purchases);

    for (final purchase in purchases) {
      debugPrint(
        '[IapService] Purchase update: ${purchase.productID} - '
        '${purchase.status}',
      );

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Verify receipt, then complete the purchase
          _verifyAndComplete(purchase);
          break;
        case PurchaseStatus.error:
          completePurchase(purchase);
          break;
        case PurchaseStatus.pending:
          // Wait for completion
          break;
        case PurchaseStatus.canceled:
          completePurchase(purchase);
          break;
      }
    }
  }

  Future<void> _verifyAndComplete(PurchaseDetails purchase) async {
    // In production, send the receipt to your backend for verification.
    // For this POC, we complete immediately.
    debugPrint('[IapService] Verifying purchase: ${purchase.productID}');
    await completePurchase(purchase);
  }

  /// Dispose of the service and cancel subscriptions.
  void dispose() {
    _subscription?.cancel();
    _purchaseController.close();
  }
}
