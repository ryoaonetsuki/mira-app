import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:mira/core/constants.dart';

/// Plays back incoming 24 kHz 16-bit mono PCM audio chunks streamed from Gemini Live.
/// Supports immediate barge-in interruption by resetting and clearing audio buffers.
class AudioPlayerService {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isOpen = false;
  bool _isPlaying = false;
  Timer? _idleTimer;

  final StreamController<double> _amplitudeController =
      StreamController<double>.broadcast();

  bool get isPlaying => _isPlaying;

  /// Output audio amplitude stream (0.0 to 1.0) while Mira is speaking.
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  /// Initialize player session.
  Future<void> init() async {
    if (_isOpen) return;
    try {
      await _player.openPlayer();
      _isOpen = true;
    } catch (_) {}
  }

  /// Ensure stream player is started.
  Future<void> _ensureStreamPlayerStarted() async {
    if (!_isOpen) {
      await init();
    }
    if (!_isPlaying) {
      try {
        await _player.startPlayerFromStream(
          codec: Codec.pcm16,
          interleaved: true,
          numChannels: MiraConstants.channels,
          sampleRate: MiraConstants.outputSampleRate, // 24000 Hz
          bufferSize: 2048,
        );
        _isPlaying = true;
      } catch (_) {}
    }
  }

  /// Feed a raw PCM chunk from Gemini Live into the player sink.
  Future<void> playChunk(Uint8List pcmChunk) async {
    if (pcmChunk.isEmpty) return;

    await _ensureStreamPlayerStarted();

    try {
      _player.uint8ListSink?.add(pcmChunk);
      _isPlaying = true;

      // Compute amplitude for speaking visualization
      final amp = _computeRms(pcmChunk);
      if (!_amplitudeController.isClosed) {
        _amplitudeController.add(amp);
      }

      // Reset idle timer to detect when speech stream pauses
      _idleTimer?.cancel();
      _idleTimer = Timer(const Duration(milliseconds: 300), () {
        if (!_amplitudeController.isClosed) {
          _amplitudeController.add(0.0);
        }
      });
    } catch (_) {}
  }

  /// Barge-in / interruption: immediately halt playback and purge buffered audio.
  Future<void> stopPlayback() async {
    _idleTimer?.cancel();
    _idleTimer = null;

    if (_isPlaying) {
      _isPlaying = false;
      try {
        await _player.stopPlayer();
      } catch (_) {}
    }

    if (!_amplitudeController.isClosed) {
      _amplitudeController.add(0.0);
    }
  }

  /// Calculate RMS amplitude from 16-bit PCM chunk.
  double _computeRms(Uint8List bytes) {
    if (bytes.length < 2) return 0.0;
    final int sampleCount = bytes.length ~/ 2;
    final ByteData byteData = bytes.buffer.asByteData(
      bytes.offsetInBytes,
      bytes.lengthInBytes,
    );

    double sumSquares = 0.0;
    for (int i = 0; i < sampleCount; i++) {
      final int sample = byteData.getInt16(i * 2, Endian.little);
      sumSquares += sample * sample;
    }

    final double rms = sqrt(sumSquares / sampleCount);
    return (rms / 32768.0).clamp(0.0, 1.0);
  }

  /// Clean up player resources.
  Future<void> dispose() async {
    await stopPlayback();
    if (_isOpen) {
      try {
        await _player.closePlayer();
      } catch (_) {}
      _isOpen = false;
    }
    await _amplitudeController.close();
  }
}
