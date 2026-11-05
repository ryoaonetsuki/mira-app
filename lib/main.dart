import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mira/core/constants.dart';
import 'package:mira/core/secure_key_storage.dart';
import 'package:mira/core/theme.dart';
import 'package:mira/screens/setup_screen.dart';
import 'package:mira/screens/voice_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for dark immersive experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: MiraTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Check if API key is already configured
  final storage = SecureKeyStorage();
  final existingKey = await storage.getApiKey();
  final hasValidKey = existingKey != null && existingKey.trim().isNotEmpty;

  runApp(MiraApp(hasConfiguredKey: hasValidKey));
}

class MiraApp extends StatelessWidget {
  final bool hasConfiguredKey;

  const MiraApp({
    super.key,
    required this.hasConfiguredKey,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: MiraConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: MiraTheme.darkTheme,
      home: hasConfiguredKey ? const VoiceScreen() : const SetupScreen(),
    );
  }
}
