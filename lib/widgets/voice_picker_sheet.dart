import 'package:flutter/material.dart';
import 'package:mira/core/constants.dart';
import 'package:mira/core/theme.dart';

/// Bottom sheet dialog for selecting a Gemini Live prebuilt voice.
class VoicePickerSheet extends StatelessWidget {
  final String currentVoice;
  final ValueChanged<String> onVoiceSelected;

  const VoicePickerSheet({
    super.key,
    required this.currentVoice,
    required this.onVoiceSelected,
  });

  static Future<String?> show(
    BuildContext context, {
    required String currentVoice,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: MiraTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: MiraTheme.border, width: 1),
      ),
      builder: (context) => VoicePickerSheet(
        currentVoice: currentVoice,
        onVoiceSelected: (voice) => Navigator.pop(context, voice),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: MiraTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Mira Voice',
                    style: TextStyle(
                      color: MiraTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Gemini Live native audio voices (Default: Kore)',
                    style: TextStyle(
                      color: MiraTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: MiraTheme.border, height: 1),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: MiraConstants.availableVoices.length,
                separatorBuilder: (context, index) =>
                    const Divider(color: MiraTheme.border, height: 1, indent: 20, endIndent: 20),
                itemBuilder: (context, index) {
                  final voice = MiraConstants.availableVoices[index];
                  final isSelected = voice.toLowerCase() == currentVoice.toLowerCase();
                  final description = MiraConstants.voiceDescriptions[voice] ?? '';

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? MiraTheme.cyanAccent.withValues(alpha: 0.15)
                            : MiraTheme.surfaceElevated,
                        border: Border.all(
                          color: isSelected ? MiraTheme.cyanAccent : MiraTheme.border,
                        ),
                      ),
                      child: Icon(
                        isSelected ? Icons.check_rounded : Icons.record_voice_over_rounded,
                        color: isSelected ? MiraTheme.cyanAccent : MiraTheme.textSecondary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      voice,
                      style: TextStyle(
                        color: isSelected ? MiraTheme.cyanAccent : MiraTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      description,
                      style: const TextStyle(
                        color: MiraTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    trailing: isSelected
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: MiraTheme.cyanAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(
                                color: MiraTheme.cyanAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                    onTap: () => onVoiceSelected(voice),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
