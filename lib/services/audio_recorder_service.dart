import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:mira/core/constants.dart';

/// Captures streaming microphone PCM audio (16 kHz, 16-bit, mono)
/// and provides real-time amplitude metrics for visualizers and barge-in.
class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _recordSubscription;

  final StreamController<Uint8List> _audioStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<double> _amplitudeController =
      StreamController<double>.broadcast();

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  /// Stream of 16-bit mono 16 kHz raw PCM audio chunks.
  Stream<Uint8List> get audioStream => _audioStreamController.stream;

  /// Stream of normalized RMS amplitudes (0.0 to 1.0) for UI waveforms.
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  /// Check and request microphone permission explicitly.
  Future<bool> checkAndRequestPermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;

    final requestStatus = await Permission.microphone.request();
    return requestStatus.isGranted;
  }

  /// Start streaming microphone audio.
  Future<bool> startStreaming() async {
    if (_isRecording) return true;

    final hasPerm = await checkAndRequestPermission();
    if (!hasPerm) return false;

    try {
      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: MiraConstants.inputSampleRate,
        numChannels: MiraConstants.channels,
        echoCancel: true,
        noiseSuppress: true,
        autoGain: true,
      );

      final stream = await _recorder.startStream(config);
      _isRecording = true;

      _recordSubscription = stream.listen(
        (chunk) {
          if (!_audioStreamController.isClosed) {
            _audioStreamController.add(chunk);
          }
          final amp = _computeRms(chunk);
          if (!_amplitudeController.isClosed) {
            _amplitudeController.add(amp);
          }
        },
        onError: (err) {
          _isRecording = false;
        },
        onDone: () {
          _isRecording = false;
        },
      );
      return true;
    } catch (_) {
      _isRecording = false;
      return false;
    }
  }

  /// Stop audio streaming.
  Future<void> stopStreaming() async {
    if (!_isRecording) return;
    _isRecording = false;
    try {
      await _recordSubscription?.cancel();
      _recordSubscription = null;
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {}
  }

  /// Calculate root-mean-square amplitude from 16-bit PCM buffer (range 0.0 - 1.0).
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
    // Normalize against 16-bit max amplitude (32768)
    final double normalized = (rms / 32768.0).clamp(0.0, 1.0);
    return normalized;
  }

  /// Dispose recorder resources.
  Future<void> dispose() async {
    await stopStreaming();
    await _audioStreamController.close();
    await _amplitudeController.close();
    await _recorder.dispose();
  }
}
