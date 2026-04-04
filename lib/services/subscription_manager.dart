import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/purchase_record.dart';
import '../models/subscription_plan.dart';

/// Manages the user's subscription state and purchase history
/// using local storage (SharedPreferences).
///
/// In production, subscription state should be stored server-side and
/// synced to the client. This implementation demonstrates the local flow.
class SubscriptionManager {
  static const String _activeSubKey = 'active_subscription';
  static const String _historyKey = 'purchase_history';
  static const String _tierKey = 'subscription_tier';

  /// Get the current active subscription tier.
  Future<SubscriptionTier> getActiveTier() async {
    final prefs = await SharedPreferences.getInstance();
    final tierName = prefs.getString(_tierKey);
    if (tierName == null) return SubscriptionTier.free;

    try {
      final tier = SubscriptionTier.values.byName(tierName);
      // Verify the subscription is not expired
      final sub = await getActiveSubscription();
      if (sub != null && sub.isActive) return tier;
      return SubscriptionTier.free;
    } catch (_) {
      return SubscriptionTier.free;
    }
  }

  /// Get the active subscription record, if any.
  Future<PurchaseRecord?> getActiveSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_activeSubKey);
    if (json == null) return null;

    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      final record = PurchaseRecord.fromJson(data);
      if (record.isActive) return record;
      return null;
    } catch (e) {
      debugPrint('[SubscriptionManager] Error reading active sub: $e');
      return null;
    }
  }

  /// Save a new active subscription.
  Future<void> activateSubscription({
    required PurchaseRecord record,
    required SubscriptionTier tier,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeSubKey, jsonEncode(record.toJson()));
    await prefs.setString(_tierKey, tier.name);
    await _addToHistory(record);
    debugPrint('[SubscriptionManager] Activated ${tier.name} subscription');
  }

  /// Cancel the active subscription.
  Future<void> cancelSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeSubKey);
    await prefs.setString(_tierKey, SubscriptionTier.free.name);
    debugPrint('[SubscriptionManager] Subscription cancelled');
  }

  /// Get the full purchase history.
  Future<List<PurchaseRecord>> getPurchaseHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_historyKey);
    if (json == null) return [];

    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => PurchaseRecord.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
    } catch (e) {
      debugPrint('[SubscriptionManager] Error reading history: $e');
      return [];
    }
  }

  /// Add a purchase record to history.
  Future<void> _addToHistory(PurchaseRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getPurchaseHistory();
    history.insert(0, record);

    final jsonList = history.map((r) => r.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  /// Add a standalone purchase (not subscription) to history.
  Future<void> recordPurchase(PurchaseRecord record) async {
    await _addToHistory(record);
    debugPrint(
      '[SubscriptionManager] Recorded purchase: ${record.productName}',
    );
  }

  /// Check if the user has premium access.
  Future<bool> hasPremiumAccess() async {
    final tier = await getActiveTier();
    return tier != SubscriptionTier.free;
  }

  /// Clear all subscription data (for testing).
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeSubKey);
    await prefs.remove(_historyKey);
    await prefs.remove(_tierKey);
    debugPrint('[SubscriptionManager] All data cleared');
  }
}
