import 'package:flutter_test/flutter_test.dart';

import 'package:cashbook/app.dart';

void main() {
  testWidgets('App launches with home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CashbookApp());
    expect(find.text('Cashbook'), findsWidgets);
  });
}
