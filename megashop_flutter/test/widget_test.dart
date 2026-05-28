// Basic smoke test for MegaShop app.
import 'package:flutter_test/flutter_test.dart';
import 'package:megashop_flutter/main.dart';

void main() {
  testWidgets('MegaShop app launches and shows home screen',
      (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const MegaShopApp());
    await tester.pump();

    // Verify the MegaShop title is present
    expect(find.text('MegaShop'), findsWidgets);

    // Verify the Trending Now section appears
    expect(find.text('Trending Now'), findsOneWidget);
  });
}
