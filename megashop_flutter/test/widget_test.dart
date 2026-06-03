// Basic smoke test for MegaShop app.
import 'package:flutter_test/flutter_test.dart';
import 'package:megashop_flutter/main.dart';

void main() {
  testWidgets('MegaShop app launches and shows introduction screen',
      (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(
      const MegaShopApp(
        hasSeenIntroduction: false,
        initialRouteOverride: '/introduction',
      ),
    );
    await tester.pump();

    expect(find.text('Welcome to MegaShop'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });
}
