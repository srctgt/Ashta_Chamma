import 'package:flutter_test/flutter_test.dart';
import 'package:ashta_chamma/main.dart';

void main() {
  testWidgets('App should display welcome text', (WidgetTester tester) async {
    await tester.pumpWidget(const AshtaChammaApp());

    expect(find.text('Ashta Chamma'), findsOneWidget);
    expect(find.textContaining('Welcome to Ashta Chamma'), findsOneWidget);
  });
}
