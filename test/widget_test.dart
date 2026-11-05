import 'package:flutter_test/flutter_test.dart';
import 'package:mira/main.dart';
import 'package:mira/screens/setup_screen.dart';
import 'package:mira/screens/voice_screen.dart';

void main() {
  testWidgets('MiraApp renders SetupScreen when no API key is configured',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MiraApp(hasConfiguredKey: false));
    expect(find.byType(SetupScreen), findsOneWidget);
    expect(find.text('Mira Setup'), findsOneWidget);
  });

  testWidgets('MiraApp renders VoiceScreen when API key is configured',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MiraApp(hasConfiguredKey: true));
    expect(find.byType(VoiceScreen), findsOneWidget);
    expect(find.text('Mira'), findsOneWidget);
  });
}
