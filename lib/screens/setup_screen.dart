import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mira/core/constants.dart';
import 'package:mira/core/secure_key_storage.dart';
import 'package:mira/core/theme.dart';
import 'package:mira/screens/voice_screen.dart';
import 'package:url_launcher/url_launcher.dart';

/// First-run BYOK (Bring Your Own Key) setup screen.
/// Validates user Gemini API key against Google AI Studio and stores it encrypted.
class SetupScreen extends StatefulWidget {
  final bool isEditing;

  const SetupScreen({super.key, this.isEditing = false});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final TextEditingController _keyController = TextEditingController();
  final SecureKeyStorage _storage = SecureKeyStorage();

  bool _obscureText = true;
  bool _isValidating = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadExistingKey();
  }

  Future<void> _loadExistingKey() async {
    final existing = await _storage.getApiKey();
    if (existing != null && mounted) {
      _keyController.text = existing;
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _launchAiStudio() async {
    final uri = Uri.parse(MiraConstants.aiStudioApiKeyUrl);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        _copyLinkToClipboard();
      }
    } catch (_) {
      if (mounted) {
        _copyLinkToClipboard();
      }
    }
  }

  void _copyLinkToClipboard() {
    Clipboard.setData(const ClipboardData(text: MiraConstants.aiStudioApiKeyUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied: https://aistudio.google.com/apikey'),
        backgroundColor: MiraTheme.surfaceElevated,
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && mounted) {
      setState(() {
        _keyController.text = data!.text!.trim();
        _errorMessage = null;
      });
    }
  }

  Future<void> _handleValidationAndSave() async {
    FocusScope.of(context).unfocus();
    final key = _keyController.text.trim();

    if (key.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your Gemini API key.';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final outcome = await _storage.validateApiKey(key);

    if (!mounted) return;

    if (outcome.isValid) {
      await _storage.saveApiKey(key);
      setState(() {
        _isValidating = false;
        _successMessage = 'API Key verified and securely saved!';
      });

      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      if (widget.isEditing) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VoiceScreen()),
        );
      }
    } else {
      setState(() {
        _isValidating = false;
        _errorMessage = outcome.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Change API Key' : 'Mira Setup'),
        leading: widget.isEditing
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mira Logo & Branding
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [MiraTheme.cyanAccent, MiraTheme.indigoAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: MiraTheme.cyanAccent.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'M',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  const Center(
                    child: Text(
                      'Welcome to Mira',
                      style: TextStyle(
                        color: MiraTheme.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text(
                      'Real-time AI voice assistant',
                      style: TextStyle(
                        color: MiraTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Information Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.shield_rounded,
                                color: MiraTheme.cyanAccent,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Private & Direct (BYOK)',
                                style: TextStyle(
                                  color: MiraTheme.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Mira is a thin client. Your API key is encrypted on your device using Android Keystore and is sent ONLY to Google\'s official servers for voice streaming.',
                            style: TextStyle(
                              color: MiraTheme.textSecondary,
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 14),
                          InkWell(
                            onTap: _launchAiStudio,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: MiraTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: MiraTheme.cyanAccent.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.open_in_new_rounded,
                                    size: 16,
                                    color: MiraTheme.cyanAccent,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Get a free key from Google AI Studio',
                                      style: TextStyle(
                                        color: MiraTheme.cyanAccent,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Key Input Field
                  TextField(
                    controller: _keyController,
                    obscureText: _obscureText,
                    style: const TextStyle(
                      color: MiraTheme.textPrimary,
                      fontSize: 15,
                      fontFamily: 'monospace',
                    ),
                    decoration: InputDecoration(
                      labelText: 'Gemini API Key',
                      hintText: 'AIzaSy...',
                      prefixIcon: const Icon(
                        Icons.key_rounded,
                        color: MiraTheme.textSecondary,
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.content_paste_rounded,
                              color: MiraTheme.cyanAccent,
                            ),
                            tooltip: 'Paste from clipboard',
                            onPressed: _pasteFromClipboard,
                          ),
                          IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: MiraTheme.textSecondary,
                            ),
                            tooltip: _obscureText ? 'Show key' : 'Hide key',
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Error & Success Feedback
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: MiraTheme.coralRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: MiraTheme.coralRed.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: MiraTheme.coralRed,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: MiraTheme.coralRed,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_successMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: MiraTheme.emeraldAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: MiraTheme.emeraldAccent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: MiraTheme.emeraldAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: const TextStyle(
                                color: MiraTheme.emeraldAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Validate & Save Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isValidating ? null : _handleValidationAndSave,
                      child: _isValidating
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Validating with Google...'),
                              ],
                            )
                          : Text(
                              widget.isEditing
                                  ? 'Save New Key'
                                  : 'Validate & Start Mira',
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'No subscription required • Free tier supported',
                      style: TextStyle(
                        color: MiraTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
