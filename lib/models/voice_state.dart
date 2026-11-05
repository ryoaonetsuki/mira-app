/// Represents the current operational state of the Mira voice engine.
enum VoiceState {
  /// Session is not active or waiting for user initiation.
  idle,

  /// Connecting WebSocket and completing setup handshake with Gemini Live.
  connecting,

  /// Microphone is active and streaming PCM audio; waiting for / receiving user speech.
  listening,

  /// User finished speaking; model is reasoning / processing before reply.
  thinking,

  /// Mira is actively streaming and playing back synthesized PCM audio.
  speaking,

  /// An error occurred (network, permission, dropped session).
  error,
}

extension VoiceStateExt on VoiceState {
  String get label {
    switch (this) {
      case VoiceState.idle:
        return 'Ready';
      case VoiceState.connecting:
        return 'Connecting...';
      case VoiceState.listening:
        return 'Listening...';
      case VoiceState.thinking:
        return 'Thinking...';
      case VoiceState.speaking:
        return 'Mira is speaking';
      case VoiceState.error:
        return 'Connection Error';
    }
  }
}
