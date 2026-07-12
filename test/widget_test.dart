import 'package:flutter_test/flutter_test.dart';
import 'package:azdal/main.dart';

void main() {
  testWidgets('App renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const AzdalApp());
    expect(find.text('مرحباً بك في أزدل'), findsOneWidget);
  });
}
