import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mira/core/theme.dart';
import 'package:mira/models/voice_state.dart';

/// Real-time audio waveform bar visualizer responsive to live PCM amplitude.
class AudioVisualizer extends StatefulWidget {
  final VoiceState state;
  final double amplitude;
  final int barCount;

  const AudioVisualizer({
    super.key,
    required this.state,
    this.amplitude = 0.0,
    this.barCount = 18,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = widget.state == VoiceState.listening ||
        widget.state == VoiceState.speaking;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return SizedBox(
          height: 36,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (index) {
              final double normalizedIndex = index / (widget.barCount - 1);
              final double centerDist = (normalizedIndex - 0.5).abs() * 2.0;

              double height = 4.0;
              if (isActive) {
                final double phase = _animController.value * 2 * pi;
                final double wave = sin(phase + (index * 0.45)).abs();
                final double amp = widget.amplitude.clamp(0.05, 1.0);
                final double envelope = 1.0 - (centerDist * 0.45);
                height = 4.0 + (wave * amp * 30.0 * envelope);
              }

              Color barColor;
              if (widget.state == VoiceState.speaking) {
                barColor = Color.lerp(
                  MiraTheme.cyanAccent,
                  MiraTheme.indigoAccent,
                  normalizedIndex,
                )!;
              } else if (widget.state == VoiceState.listening) {
                barColor = Color.lerp(
                  MiraTheme.cyanAccent,
                  MiraTheme.emeraldAccent,
                  normalizedIndex,
                )!;
              } else {
                barColor = MiraTheme.border;
              }

              return Container(
                width: 3.5,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
