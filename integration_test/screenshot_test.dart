import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_iap_stripe/app.dart';
import 'package:flutter_iap_stripe/features/paywall/paywall_provider.dart';
import 'package:flutter_iap_stripe/models/purchase_record.dart';
import 'package:flutter_iap_stripe/models/subscription_plan.dart';
import 'package:flutter_iap_stripe/services/subscription_manager.dart';

/// A seeded, in-memory subscription manager so the History and
/// Subscription screens render real-looking content without a store.
class SeededSubscriptionManager extends SubscriptionManager {
  final PurchaseRecord _active = PurchaseRecord(
    id: 'sub_active',
    productId: 'com.tranthienhau.flutter_iap_stripe.yearly',
    productName: 'Premium Yearly',
    amount: 79.99,
    source: PurchaseSource.appleIap,
    status: PurchaseStatus.completed,
    purchaseDate: DateTime(2026, 5, 18, 14, 32),
    expiryDate: DateTime(2027, 5, 18),
    transactionId: '1000000987654321',
  );

  late final List<PurchaseRecord> _history = [
    _active,
    PurchaseRecord(
      id: 'p2',
      productId: 'premium_monthly',
      productName: 'Premium Monthly',
      amount: 9.99,
      source: PurchaseSource.stripe,
      status: PurchaseStatus.completed,
      purchaseDate: DateTime(2026, 4, 18, 9, 5),
      transactionId: 'pi_3Na8Xz2eZvKYlo2C',
    ),
    PurchaseRecord(
      id: 'p3',
      productId: 'coins_pack',
      productName: 'Coin Pack (500)',
      amount: 4.99,
      source: PurchaseSource.applePay,
      status: PurchaseStatus.refunded,
      purchaseDate: DateTime(2026, 3, 2, 19, 47),
      transactionId: '1000000123498765',
    ),
    PurchaseRecord(
      id: 'p4',
      productId: 'pro_unlock',
      productName: 'Pro Unlock',
      amount: 14.99,
      source: PurchaseSource.googlePay,
      status: PurchaseStatus.completed,
      purchaseDate: DateTime(2026, 2, 11, 11, 20),
      transactionId: 'GPA.3311-1234-5678',
    ),
  ];

  @override
  Future<SubscriptionTier> getActiveTier() async => SubscriptionTier.yearly;

  @override
  Future<PurchaseRecord?> getActiveSubscription() async => _active;

  @override
  Future<List<PurchaseRecord>> getPurchaseHistory() async => _history;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shoot(WidgetTester tester, String name) async {
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot(name);
  }

  testWidgets('capture IAP + Stripe flow', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionManagerProvider.overrideWithValue(
            SeededSubscriptionManager(),
          ),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Home - feature overview.
    await shoot(tester, '01-home');

    // 2. Plans / paywall.
    await tester.tap(find.text('Plans'));
    await tester.pumpAndSettle();
    await shoot(tester, '02-paywall');

    // 3. Subscription - active premium status.
    await tester.tap(find.text('Subscription'));
    await tester.pumpAndSettle();
    await shoot(tester, '03-subscription');

    // 4. Payment history - seeded transactions.
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    await shoot(tester, '04-history');
  });
}
