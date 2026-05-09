import 'package:flutter_test/flutter_test.dart';
import 'package:schoolmate/main.dart';

void main() {
  testWidgets('Login screen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const SchoolMateApp());

    expect(find.text('SchoolMate'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Teacher'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
