import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:mira/core/constants.dart';
import 'package:mira/models/conversation_turn.dart';
import 'package:mira/models/voice_state.dart';
import 'package:mira/services/audio_player_service.dart';
import 'package:mira/services/audio_recorder_service.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

/// Manages the single real-time Gemini Live WebSocket session (`BidiGenerateContent`),
/// orchestrating bidirectional PCM streaming, barge-in interruption, and transcript updates.
class GeminiLiveService {
  final AudioPlayerService playerService;
  final AudioRecorderService recorderService;

  IOWebSocketChannel? _channel;
  StreamSubscription? _wsSubscription;
  StreamSubscription? _audioInputSubscription;

  VoiceState _state = VoiceState.idle;
  String _activeModel = MiraConstants.primaryLiveModel;
  bool _attemptedFallback = false;

  String? _currentApiKey;
  String _currentLanguage = MiraConstants.defaultLanguage;
  String _currentVoice = MiraConstants.defaultVoice;

  // Transcript tracking
  ConversationTurn? _currentUserTurn;
  ConversationTurn? _currentAssistantTurn;

  // Callbacks
  void Function(VoiceState state)? onStateChanged;
  void Function(ConversationTurn turn)? onTranscriptUpdated;
  void Function(String errorMessage)? onError;
  void Function(String activeModel)? onModelChanged;

  VoiceState get state => _state;
  String get activeModel => _activeModel;

  GeminiLiveService({
    required this.playerService,
    required this.recorderService,
  });

  void _setState(VoiceState newState) {
    if (_state != newState) {
      _state = newState;
      onStateChanged?.call(_state);
    }
  }

  /// Connect to Gemini Live WebSocket and start real-time session.
  Future<void> connect({
    required String apiKey,
    required String language,
    required String voice,
  }) async {
    _currentApiKey = apiKey;
    _currentLanguage = language;
    _currentVoice = voice;
    _activeModel = MiraConstants.primaryLiveModel;
    _attemptedFallback = false;

    await _initSession();
  }

  /// Internal session initializer with fallback support.
  Future<void> _initSession() async {
    if (_currentApiKey == null || _currentApiKey!.trim().isEmpty) {
      _setState(VoiceState.error);
      onError?.call('Missing Gemini API key. Please configure your key in settings.');
      return;
    }

    await disconnect(keepIdle: false);
    _setState(VoiceState.connecting);
    onModelChanged?.call(_activeModel);

    final wsUri = Uri.parse(
      '${MiraConstants.liveWebSocketBaseUrl}?key=${_currentApiKey!.trim()}',
    );

    try {
      // Connect WebSocket
      _channel = IOWebSocketChannel.connect(
        wsUri,
        pingInterval: const Duration(seconds: 15),
      );

      // Listen to server responses
      _wsSubscription = _channel!.stream.listen(
        _handleServerMessage,
        onError: _handleSocketError,
        onDone: _handleSocketDone,
      );

      // Send the mandatory setup message as the very first packet
      _sendSetupPacket();

      // Initialize audio player
      await playerService.init();

      // Start microphone streaming
      final startedMic = await recorderService.startStreaming();
      if (!startedMic) {
        _setState(VoiceState.error);
        onError?.call('Microphone permission denied or audio device unavailable.');
        await disconnect(keepIdle: false);
        return;
      }

      // Route mic PCM audio to the WebSocket
      _audioInputSubscription = recorderService.audioStream.listen(
        _handleMicChunk,
        onError: (err) {
          onError?.call('Microphone capture error: $err');
        },
      );
    } on SocketException catch (e) {
      _handleConnectionFailure('Network error: Cannot reach Gemini servers ($e)');
    } catch (e) {
      _handleConnectionFailure('Connection error: $e');
    }
  }

  /// Sends the initial setup configuration packet.
  void _sendSetupPacket() {
    final VoiceLanguage langObj =
        MiraConstants.getLanguageByCode(_currentLanguage);
    final setupPayload = {
      'setup': {
        'model': _activeModel,
        'generationConfig': {
          'responseModalities': ['AUDIO'],
          'speechConfig': {
            'voiceConfig': {
              'prebuiltVoiceConfig': {
                'voiceName': _currentVoice,
              },
            },
          },
        },
        'inputAudioTranscription': {
          'languageCodes': [langObj.bcp47],
        },
        'outputAudioTranscription': <String, dynamic>{},
        'systemInstruction': {
          'parts': [
            {
              'text': MiraConstants.getSystemInstruction(_currentLanguage),
            },
          ],
        },
      },
    };

    _channel?.sink.add(jsonEncode(setupPayload));
  }

  /// Handle incoming chunk from device microphone.
  void _handleMicChunk(Uint8List pcmChunk) {
    if (_state == VoiceState.idle || _state == VoiceState.error) return;

    // Barge-in detection: If Mira is actively speaking and user begins talking
    // (detected when player is playing and user amplitude is significant),
    // stop playback immediately.
    if (playerService.isPlaying && _isSpeakingAmplitude(pcmChunk)) {
      playerService.stopPlayback();
      _setState(VoiceState.listening);
    }

    // Stream base64 PCM 16kHz to Gemini Live
    final base64Chunk = base64Encode(pcmChunk);
    final packet = {
      'realtimeInput': {
        'mediaChunks': [
          {
            'mimeType': 'audio/pcm;rate=${MiraConstants.inputSampleRate}',
            'data': base64Chunk,
          },
        ],
      },
    };

    try {
      _channel?.sink.add(jsonEncode(packet));
    } catch (_) {}
  }

  /// Fast check for speaking energy threshold for instant barge-in.
  bool _isSpeakingAmplitude(Uint8List bytes) {
    if (bytes.length < 2) return false;
    final int sampleCount = bytes.length ~/ 2;
    final ByteData byteData = bytes.buffer.asByteData(
      bytes.offsetInBytes,
      bytes.lengthInBytes,
    );

    int peaks = 0;
    for (int i = 0; i < sampleCount; i += 4) {
      final int sample = byteData.getInt16(i * 2, Endian.little).abs();
      if (sample > 2400) {
        peaks++;
        if (peaks > 6) return true;
      }
    }
    return false;
  }

  /// Parse and route incoming server messages from Gemini Live.
  void _handleServerMessage(dynamic rawMessage) {
    try {
      final String text = rawMessage is String ? rawMessage : utf8.decode(rawMessage as List<int>);
      final dynamic decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) return;

      // 1. Handshake acknowledgement
      if (decoded.containsKey('setupComplete')) {
        _setState(VoiceState.listening);
        return;
      }

      // 2. Server content handling
      final serverContent = decoded['serverContent'];
      if (serverContent != null && serverContent is Map<String, dynamic>) {
        // Barge-in signaled from Gemini VAD
        if (serverContent['interrupted'] == true) {
          playerService.stopPlayback();
          _setState(VoiceState.listening);
        }

        // Assistant Audio and Text Output
        final modelTurn = serverContent['modelTurn'];
        if (modelTurn != null && modelTurn is Map<String, dynamic>) {
          final parts = modelTurn['parts'];
          if (parts is List) {
            for (final part in parts) {
              if (part is Map<String, dynamic>) {
                // Audio PCM payload (24 kHz)
                final inlineData = part['inlineData'];
                if (inlineData is Map<String, dynamic>) {
                  final String? base64Data = inlineData['data'];
                  if (base64Data != null && base64Data.isNotEmpty) {
                    final pcmBytes = base64Decode(base64Data);
                    playerService.playChunk(pcmBytes);
                    _setState(VoiceState.speaking);
                  }
                }

                // Incremental text reply
                final String? textChunk = part['text'];
                if (textChunk != null && textChunk.isNotEmpty) {
                  _appendAssistantTranscript(textChunk, isInterim: true);
                }
              }
            }
          }
        }

        // Spoken output transcription
        final outputTranscription = serverContent['outputTranscription'];
        if (outputTranscription is Map<String, dynamic>) {
          final String? outText = outputTranscription['text'];
          if (outText != null && outText.isNotEmpty) {
            _appendAssistantTranscript(outText, isInterim: true);
          }
        }

        // User speech transcription
        final inputTranscription = serverContent['inputTranscription'];
        if (inputTranscription is Map<String, dynamic>) {
          final String? inText = inputTranscription['text'];
          if (inText != null && inText.isNotEmpty) {
            _updateUserTranscript(inText, isInterim: false);
          }
        }

        final interimInput = serverContent['interimInputTranscription'];
        if (interimInput is Map<String, dynamic>) {
          final String? interimText = interimInput['text'];
          if (interimText != null && interimText.isNotEmpty) {
            _updateUserTranscript(interimText, isInterim: true);
          }
        }

        // Turn completion
        if (serverContent['turnComplete'] == true) {
          _finalizeTurn();
        }
      }
    } catch (_) {}
  }

  void _updateUserTranscript(String text, {required bool isInterim}) {
    if (_currentUserTurn == null || !_currentUserTurn!.isInterim) {
      _currentUserTurn = ConversationTurn(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        isUser: true,
        text: text,
        isInterim: isInterim,
      );
    } else {
      _currentUserTurn!.text = text;
      _currentUserTurn!.isInterim = isInterim;
    }
    onTranscriptUpdated?.call(_currentUserTurn!);

    // When user starts speaking, UI is listening/thinking
    if (_state != VoiceState.speaking && _state != VoiceState.listening) {
      _setState(VoiceState.listening);
    }
  }

  void _appendAssistantTranscript(String textChunk, {required bool isInterim}) {
    if (_currentAssistantTurn == null || !_currentAssistantTurn!.isInterim) {
      _currentAssistantTurn = ConversationTurn(
        id: 'mira_${DateTime.now().millisecondsSinceEpoch}',
        isUser: false,
        text: textChunk,
        isInterim: isInterim,
      );
    } else {
      _currentAssistantTurn!.text += textChunk;
      _currentAssistantTurn!.isInterim = isInterim;
    }
    onTranscriptUpdated?.call(_currentAssistantTurn!);
  }

  void _finalizeTurn() {
    if (_currentUserTurn != null && _currentUserTurn!.isInterim) {
      _currentUserTurn!.isInterim = false;
      onTranscriptUpdated?.call(_currentUserTurn!);
    }
    if (_currentAssistantTurn != null && _currentAssistantTurn!.isInterim) {
      _currentAssistantTurn!.isInterim = false;
      onTranscriptUpdated?.call(_currentAssistantTurn!);
    }

    if (!playerService.isPlaying && _state == VoiceState.speaking) {
      _setState(VoiceState.listening);
    }
  }

  void _handleSocketError(dynamic error) {
    if (!_attemptedFallback && _activeModel == MiraConstants.primaryLiveModel) {
      _attemptFallback();
    } else {
      _setState(VoiceState.error);
      onError?.call('Gemini Live session error: $error');
    }
  }

  void _handleSocketDone() {
    if (_state == VoiceState.idle) return;

    if (!_attemptedFallback && _activeModel == MiraConstants.primaryLiveModel) {
      _attemptFallback();
    } else {
      _setState(VoiceState.error);
      onError?.call('Gemini Live session disconnected. Tap Reconnect to resume.');
    }
  }

  void _handleConnectionFailure(String reason) {
    if (!_attemptedFallback && _activeModel == MiraConstants.primaryLiveModel) {
      _attemptFallback();
    } else {
      _setState(VoiceState.error);
      onError?.call(reason);
    }
  }

  /// Automatically fall back to secondary model if primary model is unavailable.
  void _attemptFallback() {
    _attemptedFallback = true;
    _activeModel = MiraConstants.fallbackLiveModel;
    onModelChanged?.call(_activeModel);
    _initSession();
  }

  /// Disconnect the active live session.
  Future<void> disconnect({bool keepIdle = true}) async {
    await _audioInputSubscription?.cancel();
    _audioInputSubscription = null;

    await _wsSubscription?.cancel();
    _wsSubscription = null;

    try {
      await _channel?.sink.close(ws_status.normalClosure);
    } catch (_) {}
    _channel = null;

    await recorderService.stopStreaming();
    await playerService.stopPlayback();

    _currentUserTurn = null;
    _currentAssistantTurn = null;

    if (keepIdle) {
      _setState(VoiceState.idle);
    }
  }

  /// Reconnect with current configuration.
  Future<void> reconnect() async {
    if (_currentApiKey != null) {
      await connect(
        apiKey: _currentApiKey!,
        language: _currentLanguage,
        voice: _currentVoice,
      );
    }
  }

  /// Clean up all resources.
  Future<void> dispose() async {
    await disconnect();
  }
}
