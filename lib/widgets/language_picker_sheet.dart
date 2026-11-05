import 'package:flutter/material.dart';
import 'package:mira/core/constants.dart';
import 'package:mira/core/theme.dart';

/// Bottom sheet dialog for choosing the conversation language from a comprehensive list.
class LanguagePickerSheet extends StatefulWidget {
  final String currentLanguage;
  final ValueChanged<String> onLanguageSelected;

  const LanguagePickerSheet({
    super.key,
    required this.currentLanguage,
    required this.onLanguageSelected,
  });

  static Future<String?> show(
    BuildContext context, {
    required String currentLanguage,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: MiraTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: MiraTheme.border, width: 1),
      ),
      builder: (context) => LanguagePickerSheet(
        currentLanguage: currentLanguage,
        onLanguageSelected: (lang) => Navigator.pop(context, lang),
      ),
    );
  }

  @override
  State<LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<LanguagePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<VoiceLanguage> _filteredLanguages = MiraConstants.supportedLanguages;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredLanguages = MiraConstants.supportedLanguages;
      } else {
        _filteredLanguages = MiraConstants.supportedLanguages.where((lang) {
          return lang.englishName.toLowerCase().contains(query) ||
              lang.nativeName.toLowerCase().contains(query) ||
              lang.code.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
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

            // Sheet Title & Description
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spoken Language',
                    style: TextStyle(
                      color: MiraTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Select the language Mira speaks and understands. The app UI remains in English.',
                    style: TextStyle(
                      color: MiraTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Search Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  color: MiraTheme.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search language...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: MiraTheme.textSecondary,
                    size: 20,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Divider(color: MiraTheme.border, height: 1),

            // Language List
            Flexible(
              child: _filteredLanguages.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No matching languages found.',
                          style: TextStyle(
                            color: MiraTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _filteredLanguages.length,
                      separatorBuilder: (context, index) => const Divider(
                        color: MiraTheme.border,
                        height: 1,
                        indent: 20,
                        endIndent: 20,
                      ),
                      itemBuilder: (context, index) {
                        final lang = _filteredLanguages[index];
                        final isSelected =
                            lang.code.toLowerCase() == widget.currentLanguage.toLowerCase();

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 2,
                          ),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? MiraTheme.cyanAccent.withValues(alpha: 0.15)
                                  : MiraTheme.surfaceElevated,
                              border: Border.all(
                                color: isSelected
                                    ? MiraTheme.cyanAccent
                                    : MiraTheme.border,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                lang.code.toUpperCase(),
                                style: TextStyle(
                                  color: isSelected
                                      ? MiraTheme.cyanAccent
                                      : MiraTheme.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            lang.englishName,
                            style: TextStyle(
                              color: isSelected
                                  ? MiraTheme.cyanAccent
                                  : MiraTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            lang.nativeName,
                            style: const TextStyle(
                              color: MiraTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          trailing: isSelected
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: MiraTheme.cyanAccent
                                        .withValues(alpha: 0.15),
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
                          onTap: () => widget.onLanguageSelected(lang.code),
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
