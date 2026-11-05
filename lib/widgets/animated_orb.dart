import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mira/core/theme.dart';
import 'package:mira/models/voice_state.dart';

/// An animated orb / listening indicator showcasing real-time voice states:
/// idle, connecting, listening, thinking, speaking, and error.
class AnimatedOrb extends StatefulWidget {
  final VoiceState state;
  final double amplitude;
  final VoidCallback? onTap;

  const AnimatedOrb({
    super.key,
    required this.state,
    this.amplitude = 0.0,
    this.onTap,
  });

  @override
  State<AnimatedOrb> createState() => _AnimatedOrbState();
}

class _AnimatedOrbState extends State<AnimatedOrb>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  List<Color> _getGradientColors() {
    switch (widget.state) {
      case VoiceState.idle:
        return const [
          Color(0xFF1E293B),
          Color(0xFF0F172A),
          Color(0xFF334155),
        ];
      case VoiceState.connecting:
        return const [
          MiraTheme.cyanAccent,
          MiraTheme.indigoAccent,
          Color(0xFF3B82F6),
        ];
      case VoiceState.listening:
        return const [
          MiraTheme.cyanAccent,
          MiraTheme.emeraldAccent,
          Color(0xFF06B6D4),
        ];
      case VoiceState.thinking:
        return const [
          MiraTheme.amberAccent,
          MiraTheme.indigoAccent,
          Color(0xFFEC4899),
        ];
      case VoiceState.speaking:
        return const [
          MiraTheme.cyanAccent,
          MiraTheme.indigoAccent,
          Color(0xFF8B5CF6),
        ];
      case VoiceState.error:
        return const [
          MiraTheme.coralRed,
          Color(0xFF991B1B),
          Color(0xFFF87171),
        ];
    }
  }

  Color _getPrimaryAccent() {
    switch (widget.state) {
      case VoiceState.idle:
        return MiraTheme.textMuted;
      case VoiceState.connecting:
        return MiraTheme.cyanAccent;
      case VoiceState.listening:
        return MiraTheme.emeraldAccent;
      case VoiceState.thinking:
        return MiraTheme.amberAccent;
      case VoiceState.speaking:
        return MiraTheme.cyanAccent;
      case VoiceState.error:
        return MiraTheme.coralRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseController,
        _rotationController,
        _waveController,
      ]),
      builder: (context, child) {
        final double pulse = _pulseController.value;
        final double rotation = _rotationController.value * 2 * pi;
        final double ampScale = (widget.amplitude * 0.4).clamp(0.0, 0.4);

        // Dynamic size adjustments based on state and live amplitude
        double baseScale = 1.0;
        if (widget.state == VoiceState.listening ||
            widget.state == VoiceState.speaking) {
          baseScale = 1.0 + (pulse * 0.08) + ampScale;
        } else if (widget.state == VoiceState.connecting) {
          baseScale = 0.95 + (pulse * 0.05);
        } else if (widget.state == VoiceState.thinking) {
          baseScale = 0.98 + (sin(rotation * 2) * 0.04);
        }

        final colors = _getGradientColors();
        final primaryAccent = _getPrimaryAccent();

        return GestureDetector(
          onTap: widget.onTap,
          child: SizedBox(
            width: 240,
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer ambient glow ring
                Transform.scale(
                  scale: baseScale * 1.25,
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryAccent.withValues(
                            alpha: widget.state == VoiceState.idle ? 0.05 : 0.25 + (ampScale * 0.5),
                          ),
                          blurRadius: 45 + (ampScale * 30),
                          spreadRadius: 10 + (ampScale * 15),
                        ),
                      ],
                    ),
                  ),
                ),

                // Rotating gradient outer ring
                Transform.rotate(
                  angle: rotation,
                  child: Container(
                    width: 170 * baseScale,
                    height: 170 * baseScale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          ...colors,
                          colors.first,
                        ],
                      ),
                    ),
                  ),
                ),

                // Inner core with glassmorphism shading
                Container(
                  width: 154 * baseScale,
                  height: 154 * baseScale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: MiraTheme.background,
                    gradient: RadialGradient(
                      center: Alignment.topLeft,
                      radius: 0.9,
                      colors: [
                        colors[0].withValues(alpha: 0.85),
                        colors[1].withValues(alpha: 0.95),
                        MiraTheme.background,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _buildCenterIcon(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCenterIcon() {
    IconData icon;
    Color iconColor = Colors.white;

    switch (widget.state) {
      case VoiceState.idle:
        icon = Icons.mic_none_rounded;
        iconColor = MiraTheme.textSecondary;
        break;
      case VoiceState.connecting:
        icon = Icons.sync_rounded;
        iconColor = MiraTheme.cyanAccent;
        break;
      case VoiceState.listening:
        icon = Icons.mic_rounded;
        iconColor = MiraTheme.cyanAccent;
        break;
      case VoiceState.thinking:
        icon = Icons.auto_awesome_rounded;
        iconColor = MiraTheme.amberAccent;
        break;
      case VoiceState.speaking:
        icon = Icons.graphic_eq_rounded;
        iconColor = MiraTheme.cyanAccent;
        break;
      case VoiceState.error:
        icon = Icons.error_outline_rounded;
        iconColor = MiraTheme.coralRed;
        break;
    }

    return Icon(
      icon,
      size: 46,
      color: iconColor,
    );
  }
}
