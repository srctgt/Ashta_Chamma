import 'package:flutter_test/flutter_test.dart';
import 'package:ashta_chamma/main.dart';

void main() {
  testWidgets('App should display home screen with title',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AshtaChammaApp());

    expect(find.text('Ashta Chamma'), findsOneWidget);
    expect(find.text('Human vs Human'), findsOneWidget);
    expect(find.text('Human vs AI'), findsOneWidget);
  });
}
