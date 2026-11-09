import 'package:flutter_test/flutter_test.dart';
import 'package:vms_frontend/app/app.dart';

void main() {
  testWidgets('Login validates required credentials before sending', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const VmsApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your work email.'), findsOneWidget);
    expect(find.text('Enter a password to continue.'), findsOneWidget);
  });
}
