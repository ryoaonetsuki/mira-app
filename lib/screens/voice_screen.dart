import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mira/core/constants.dart';
import 'package:mira/core/secure_key_storage.dart';
import 'package:mira/core/theme.dart';
import 'package:mira/models/conversation_turn.dart';
import 'package:mira/models/voice_state.dart';
import 'package:mira/screens/setup_screen.dart';
import 'package:mira/services/audio_player_service.dart';
import 'package:mira/services/audio_recorder_service.dart';
import 'package:mira/services/gemini_live_service.dart';
import 'package:mira/widgets/animated_orb.dart';
import 'package:mira/widgets/audio_visualizer.dart';
import 'package:mira/widgets/language_picker_sheet.dart';
import 'package:mira/widgets/transcript_view.dart';
import 'package:mira/widgets/voice_picker_sheet.dart';

/// Main voice conversation screen of Mira.
class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> with WidgetsBindingObserver {
  final SecureKeyStorage _storage = SecureKeyStorage();
  late final AudioPlayerService _playerService;
  late final AudioRecorderService _recorderService;
  late final GeminiLiveService _liveService;

  StreamSubscription? _playerAmpSub;
  StreamSubscription? _recorderAmpSub;

  VoiceState _state = VoiceState.idle;
  double _currentAmplitude = 0.0;
  String _selectedVoice = MiraConstants.defaultVoice;
  String _selectedLanguage = MiraConstants.defaultLanguage;
  String _activeModel = MiraConstants.primaryLiveModel;
  String? _errorMessage;

  final List<ConversationTurn> _turns = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _playerService = AudioPlayerService();
    _recorderService = AudioRecorderService();
    _liveService = GeminiLiveService(
      playerService: _playerService,
      recorderService: _recorderService,
    );

    _setupCallbacks();
    _loadInitialConfig();
  }

  void _setupCallbacks() {
    _liveService.onStateChanged = (newState) {
      if (!mounted) return;
      setState(() {
        _state = newState;
        if (newState != VoiceState.error) {
          _errorMessage = null;
        }
      });
    };

    _liveService.onTranscriptUpdated = (turn) {
      if (!mounted) return;
      setState(() {
        final existingIndex = _turns.indexWhere((t) => t.id == turn.id);
        if (existingIndex >= 0) {
          _turns[existingIndex] = turn;
        } else {
          _turns.add(turn);
        }
      });
    };

    _liveService.onError = (err) {
      if (!mounted) return;
      setState(() {
        _errorMessage = err;
        _state = VoiceState.error;
      });
    };

    _liveService.onModelChanged = (model) {
      if (!mounted) return;
      setState(() {
        _activeModel = model;
      });
    };

    // Listen to live amplitudes for orb pulsation & visualizer
    _recorderAmpSub = _recorderService.amplitudeStream.listen((amp) {
      if (mounted && (_state == VoiceState.listening || _state == VoiceState.connecting)) {
        setState(() {
          _currentAmplitude = amp;
        });
      }
    });

    _playerAmpSub = _playerService.amplitudeStream.listen((amp) {
      if (mounted && _state == VoiceState.speaking) {
        setState(() {
          _currentAmplitude = amp;
        });
      }
    });
  }

  Future<void> _loadInitialConfig() async {
    final key = await _storage.getApiKey();
    if (key == null || key.isEmpty) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SetupScreen()),
      );
      return;
    }

    final voice = await _storage.getSelectedVoice();
    final lang = await _storage.getSelectedLanguage();

    if (mounted) {
      setState(() {
        _selectedVoice = voice;
        _selectedLanguage = lang;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.paused ||
        lifecycleState == AppLifecycleState.detached) {
      _liveService.disconnect();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _playerAmpSub?.cancel();
    _recorderAmpSub?.cancel();
    _liveService.dispose();
    _playerService.dispose();
    _recorderService.dispose();
    super.dispose();
  }

  Future<void> _toggleConversation() async {
    if (_state == VoiceState.idle || _state == VoiceState.error) {
      final key = await _storage.getApiKey();
      if (key == null || key.trim().isEmpty) {
        _promptForApiKey();
        return;
      }

      setState(() {
        _errorMessage = null;
      });

      await _liveService.connect(
        apiKey: key,
        language: _selectedLanguage,
        voice: _selectedVoice,
      );
    } else {
      await _liveService.disconnect();
      setState(() {
        _currentAmplitude = 0.0;
      });
    }
  }

  void _promptForApiKey() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Gemini API key is missing. Please add it first.'),
        action: SnackBarAction(
          label: 'Setup Key',
          textColor: MiraTheme.cyanAccent,
          onPressed: _openSettings,
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const SetupScreen(isEditing: true),
      ),
    );

    if (changed == true && mounted) {
      final wasActive = _state != VoiceState.idle && _state != VoiceState.error;
      await _liveService.disconnect();
      if (wasActive) {
        _toggleConversation();
      }
    }
  }

  Future<void> _pickVoice() async {
    final newVoice = await VoicePickerSheet.show(
      context,
      currentVoice: _selectedVoice,
    );

    if (newVoice != null && newVoice != _selectedVoice && mounted) {
      setState(() {
        _selectedVoice = newVoice;
      });
      await _storage.saveSelectedVoice(newVoice);

      if (_state != VoiceState.idle && _state != VoiceState.error) {
        await _liveService.reconnect();
      }
    }
  }

  Future<void> _pickLanguage() async {
    final newLang = await LanguagePickerSheet.show(
      context,
      currentLanguage: _selectedLanguage,
    );

    if (newLang != null && newLang != _selectedLanguage && mounted) {
      setState(() {
        _selectedLanguage = newLang;
      });
      await _storage.saveSelectedLanguage(newLang);

      if (_state != VoiceState.idle && _state != VoiceState.error) {
        await _liveService.reconnect();
      }
    }
  }

  void _clearTranscript() {
    setState(() {
      _turns.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = _state != VoiceState.idle && _state != VoiceState.error;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getStatusIndicatorColor(),
              ),
            ),
            const Text(
              MiraConstants.appName,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: MiraTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: MiraTheme.border),
              ),
              child: Text(
                _selectedLanguage.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: MiraTheme.cyanAccent,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Language selector
          IconButton(
            icon: const Icon(Icons.language_rounded),
            tooltip: 'Choose language',
            onPressed: _pickLanguage,
          ),
          // Voice selector
          IconButton(
            icon: const Icon(Icons.record_voice_over_rounded),
            tooltip: 'Choose voice ($_selectedVoice)',
            onPressed: _pickVoice,
          ),
          // Settings / Change key
          IconButton(
            icon: const Icon(Icons.key_rounded),
            tooltip: 'API key & settings',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Error banner if connection dropped or failed
            if (_errorMessage != null) _buildErrorBanner(),

            // Model / Status indicator header
            _buildStatusHeader(),

            // Live conversation transcript
            Expanded(
              child: TranscriptView(
                turns: _turns,
                onClear: _turns.isNotEmpty ? _clearTranscript : null,
              ),
            ),

            // Animated orb & visualizer section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedOrb(
                    state: _state,
                    amplitude: _currentAmplitude,
                    onTap: _toggleConversation,
                  ),
                  const SizedBox(height: 8),
                  AudioVisualizer(
                    state: _state,
                    amplitude: _currentAmplitude,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _state.label,
                    style: const TextStyle(
                      color: MiraTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Bottom microphone control button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: _buildActionButton(isActive),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusIndicatorColor() {
    switch (_state) {
      case VoiceState.idle:
        return MiraTheme.textMuted;
      case VoiceState.connecting:
        return MiraTheme.cyanAccent;
      case VoiceState.listening:
        return MiraTheme.emeraldAccent;
      case VoiceState.thinking:
        return MiraTheme.amberAccent;
      case VoiceState.speaking:
        return MiraTheme.indigoAccent;
      case VoiceState.error:
        return MiraTheme.coralRed;
    }
  }

  Widget _buildStatusHeader() {
    final isFallback = _activeModel == MiraConstants.fallbackLiveModel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: MiraTheme.surfaceElevated.withValues(alpha: 0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Status: ${_state.label}',
                style: const TextStyle(
                  color: MiraTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                isFallback ? '2.5-flash-audio (fallback)' : '3.8-live',
                style: TextStyle(
                  color: isFallback ? MiraTheme.amberAccent : MiraTheme.textMuted,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _pickVoice,
                child: Text(
                  'Voice: $_selectedVoice',
                  style: const TextStyle(
                    color: MiraTheme.cyanAccent,
                    fontSize: 11,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: MiraTheme.coralRed.withValues(alpha: 0.15),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: MiraTheme.coralRed, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: MiraTheme.coralRed,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MiraTheme.coralRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => _liveService.reconnect(),
            child: const Text('Reconnect', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(bool isActive) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? MiraTheme.coralRed : MiraTheme.cyanAccent,
          foregroundColor: isActive ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
          ),
          elevation: 4,
          shadowColor: (isActive ? MiraTheme.coralRed : MiraTheme.cyanAccent)
              .withValues(alpha: 0.4),
        ),
        onPressed: _toggleConversation,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.stop_rounded : Icons.mic_rounded,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              isActive
                  ? 'End Conversation'
                  : 'Tap to Talk',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
