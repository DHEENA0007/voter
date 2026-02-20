import 'package:flutter_test/flutter_test.dart';
import 'package:voting_app/main.dart';

void main() {
  testWidgets('App loads splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const VotingApp());
    // Splash screen should show app name
    expect(find.text('Secure Voting'), findsOneWidget);
  });
}
