/// Represents a spoken language supported by Gemini Live.
class VoiceLanguage {
  final String code;
  final String englishName;
  final String nativeName;
  final String bcp47;

  const VoiceLanguage({
    required this.code,
    required this.englishName,
    required this.nativeName,
    required this.bcp47,
  });
}

/// App constants for Mira voice assistant.
class MiraConstants {
  static const String appName = 'Mira';
  static const String appTagline = 'AI Voice Assistant';

  // Gemini Live Models
  static const String primaryLiveModel = 'models/gemini-3.8-live';
  static const String fallbackLiveModel =
      'models/gemini-2.5-flash-native-audio-preview-12-2025';

  // WebSocket Endpoint
  static const String liveWebSocketBaseUrl =
      'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent';

  // Audio Specifications
  static const int inputSampleRate = 16000;
  static const int outputSampleRate = 24000;
  static const int channels = 1;

  // AI Studio API Key URL
  static const String aiStudioApiKeyUrl = 'https://aistudio.google.com/apikey';

  // Storage Keys
  static const String storageKeyGeminiApi = 'mira_gemini_api_key';
  static const String storageKeySelectedVoice = 'mira_selected_voice';
  static const String storageKeySelectedLanguage = 'mira_selected_language';

  // Default Voice: Kore
  static const String defaultVoice = 'Kore';

  // Default Language: English
  static const String defaultLanguage = 'en';

  // Supported Gemini Live Voices
  static const List<String> availableVoices = [
    'Aoede',
    'Kore',
    'Puck',
    'Fenrir',
    'Charon',
    'Zephyr',
    'Autonoe',
    'Callirrhoe',
    'Despina',
    'Erinome',
    'Gacrux',
    'Laomedeia',
    'Leda',
    'Sulafat',
    'Vindemiatrix',
  ];

  // Voice descriptions for user guidance
  static const Map<String, String> voiceDescriptions = {
    'Aoede': 'Breezy & expressive soprano',
    'Kore': 'Warm, natural & clear (Default)',
    'Puck': 'Lively & energetic',
    'Fenrir': 'Deep, resonant & authoritative',
    'Charon': 'Calm, thoughtful & steady',
    'Zephyr': 'Soft, soothing & relaxed',
    'Autonoe': 'Bright & melodic',
    'Callirrhoe': 'Gentle & conversational',
    'Despina': 'Smooth & composed',
    'Erinome': 'Warm & articulate',
    'Gacrux': 'Rich & assertive',
    'Laomedeia': 'Clear & direct',
    'Leda': 'Friendly & inviting',
    'Sulafat': 'Deep & grounded',
    'Vindemiatrix': 'Dynamic & expressive',
  };

  /// Comprehensive list of spoken languages supported by Gemini Live.
  static const List<VoiceLanguage> supportedLanguages = [
    VoiceLanguage(code: 'en', englishName: 'English', nativeName: 'English', bcp47: 'en-US'),
    VoiceLanguage(code: 'bn', englishName: 'Bengali (Bangla)', nativeName: 'বাংলা', bcp47: 'bn-BD'),
    VoiceLanguage(code: 'hi', englishName: 'Hindi', nativeName: 'हिन्दी', bcp47: 'hi-IN'),
    VoiceLanguage(code: 'ur', englishName: 'Urdu', nativeName: 'اردو', bcp47: 'ur-PK'),
    VoiceLanguage(code: 'ne', englishName: 'Nepali', nativeName: 'नेपाली', bcp47: 'ne-NP'),
    VoiceLanguage(code: 'ta', englishName: 'Tamil', nativeName: 'தமிழ்', bcp47: 'ta-IN'),
    VoiceLanguage(code: 'te', englishName: 'Telugu', nativeName: 'తెలుగు', bcp47: 'te-IN'),
    VoiceLanguage(code: 'mr', englishName: 'Marathi', nativeName: 'मराठी', bcp47: 'mr-IN'),
    VoiceLanguage(code: 'pa', englishName: 'Punjabi', nativeName: 'ਪੰਜਾਬੀ', bcp47: 'pa-IN'),
    VoiceLanguage(code: 'ml', englishName: 'Malayalam', nativeName: 'മലയാളം', bcp47: 'ml-IN'),
    VoiceLanguage(code: 'gu', englishName: 'Gujarati', nativeName: 'ગુજરાતી', bcp47: 'gu-IN'),
    VoiceLanguage(code: 'kn', englishName: 'Kannada', nativeName: 'ಕನ್ನಡ', bcp47: 'kn-IN'),
    VoiceLanguage(code: 'ar', englishName: 'Arabic', nativeName: 'العربية', bcp47: 'ar-XA'),
    VoiceLanguage(code: 'es', englishName: 'Spanish', nativeName: 'Español', bcp47: 'es-ES'),
    VoiceLanguage(code: 'fr', englishName: 'French', nativeName: 'Français', bcp47: 'fr-FR'),
    VoiceLanguage(code: 'de', englishName: 'German', nativeName: 'Deutsch', bcp47: 'de-DE'),
    VoiceLanguage(code: 'pt', englishName: 'Portuguese', nativeName: 'Português', bcp47: 'pt-BR'),
    VoiceLanguage(code: 'it', englishName: 'Italian', nativeName: 'Italiano', bcp47: 'it-IT'),
    VoiceLanguage(code: 'ja', englishName: 'Japanese', nativeName: '日本語', bcp47: 'ja-JP'),
    VoiceLanguage(code: 'ko', englishName: 'Korean', nativeName: '한국어', bcp47: 'ko-KR'),
    VoiceLanguage(code: 'zh', englishName: 'Chinese (Mandarin)', nativeName: '中文', bcp47: 'zh-CN'),
    VoiceLanguage(code: 'ru', englishName: 'Russian', nativeName: 'Русский', bcp47: 'ru-RU'),
    VoiceLanguage(code: 'tr', englishName: 'Turkish', nativeName: 'Türkçe', bcp47: 'tr-TR'),
    VoiceLanguage(code: 'id', englishName: 'Indonesian', nativeName: 'Bahasa Indonesia', bcp47: 'id-ID'),
    VoiceLanguage(code: 'vi', englishName: 'Vietnamese', nativeName: 'Tiếng Việt', bcp47: 'vi-VN'),
    VoiceLanguage(code: 'th', englishName: 'Thai', nativeName: 'ไทย', bcp47: 'th-TH'),
    VoiceLanguage(code: 'nl', englishName: 'Dutch', nativeName: 'Nederlands', bcp47: 'nl-NL'),
    VoiceLanguage(code: 'pl', englishName: 'Polish', nativeName: 'Polski', bcp47: 'pl-PL'),
    VoiceLanguage(code: 'uk', englishName: 'Ukrainian', nativeName: 'Українська', bcp47: 'uk-UA'),
    VoiceLanguage(code: 'fil', englishName: 'Filipino (Tagalog)', nativeName: 'Filipino', bcp47: 'fil-PH'),
    VoiceLanguage(code: 'sv', englishName: 'Swedish', nativeName: 'Svenska', bcp47: 'sv-SE'),
    VoiceLanguage(code: 'el', englishName: 'Greek', nativeName: 'Ελληνικά', bcp47: 'el-GR'),
    VoiceLanguage(code: 'ro', englishName: 'Romanian', nativeName: 'Română', bcp47: 'ro-RO'),
    VoiceLanguage(code: 'cs', englishName: 'Czech', nativeName: 'Čeština', bcp47: 'cs-CZ'),
    VoiceLanguage(code: 'hu', englishName: 'Hungarian', nativeName: 'Magyar', bcp47: 'hu-HU'),
    VoiceLanguage(code: 'da', englishName: 'Danish', nativeName: 'Dansk', bcp47: 'da-DK'),
    VoiceLanguage(code: 'fi', englishName: 'Finnish', nativeName: 'Suomi', bcp47: 'fi-FI'),
    VoiceLanguage(code: 'no', englishName: 'Norwegian', nativeName: 'Norsk', bcp47: 'no-NO'),
    VoiceLanguage(code: 'ms', englishName: 'Malay', nativeName: 'Bahasa Melayu', bcp47: 'ms-MY'),
  ];

  static VoiceLanguage getLanguageByCode(String code) {
    return supportedLanguages.firstWhere(
      (lang) => lang.code.toLowerCase() == code.toLowerCase(),
      orElse: () => supportedLanguages.first,
    );
  }

  /// Generate the system instruction directing Mira to converse in the user's chosen language.
  static String getSystemInstruction(String languageCode) {
    final language = getLanguageByCode(languageCode);
    final targetLang = language.englishName;

    return 'You are Mira, a friendly, warm, and natural AI voice assistant. '
        'Always reply and converse in natural, fluent spoken $targetLang. '
        'Keep your responses concise, conversational, and direct, optimized for real-time voice speech. '
        'Avoid markdown formatting, bullet points, asterisks, or numbered lists; '
        'speak naturally as if talking to a friend on a phone call. '
        'If the user greets you or asks who you are, introduce yourself warmly as Mira.';
  }
}
