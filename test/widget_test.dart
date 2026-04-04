import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_iap_stripe/app.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));

    expect(find.text('Flutter IAP + Stripe'), findsWidgets);
    expect(find.text('Payment Integrations'), findsOneWidget);
  });
}
