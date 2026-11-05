import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mira/core/constants.dart';

enum KeyValidationResult {
  valid,
  invalidKey,
  networkError,
  serverError,
  emptyKey,
}

class ValidationOutcome {
  final KeyValidationResult result;
  final String message;

  ValidationOutcome(this.result, this.message);

  bool get isValid => result == KeyValidationResult.valid;
}

/// Manages secure hardware-encrypted storage (Android Keystore via flutter_secure_storage)
/// and validation against Google's Gemini API endpoints.
class SecureKeyStorage {
  static final SecureKeyStorage _instance = SecureKeyStorage._internal();
  factory SecureKeyStorage() => _instance;
  SecureKeyStorage._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Retrieve the stored Gemini API key, or null if none is saved.
  Future<String?> getApiKey() async {
    try {
      return await _storage.read(key: MiraConstants.storageKeyGeminiApi);
    } catch (_) {
      return null;
    }
  }

  /// Store the validated API key securely in device keystore.
  Future<void> saveApiKey(String apiKey) async {
    await _storage.write(
      key: MiraConstants.storageKeyGeminiApi,
      value: apiKey.trim(),
    );
  }

  /// Delete the API key from device storage.
  Future<void> deleteApiKey() async {
    await _storage.delete(key: MiraConstants.storageKeyGeminiApi);
  }

  /// Retrieve saved voice preference (default: Kore).
  Future<String> getSelectedVoice() async {
    try {
      final voice = await _storage.read(key: MiraConstants.storageKeySelectedVoice);
      if (voice != null && MiraConstants.availableVoices.contains(voice)) {
        return voice;
      }
    } catch (_) {}
    return MiraConstants.defaultVoice;
  }

  /// Save voice preference.
  Future<void> saveSelectedVoice(String voice) async {
    await _storage.write(
      key: MiraConstants.storageKeySelectedVoice,
      value: voice,
    );
  }

  /// Retrieve saved language preference (default: en).
  Future<String> getSelectedLanguage() async {
    try {
      final lang = await _storage.read(key: MiraConstants.storageKeySelectedLanguage);
      if (lang != null &&
          MiraConstants.supportedLanguages.any((l) => l.code == lang)) {
        return lang;
      }
    } catch (_) {}
    return MiraConstants.defaultLanguage;
  }

  /// Save language preference.
  Future<void> saveSelectedLanguage(String lang) async {
    await _storage.write(
      key: MiraConstants.storageKeySelectedLanguage,
      value: lang,
    );
  }

  /// Validate the API key using a minimal, cheap Gemini API call (`list models`).
  ///
  /// This endpoint lists available models without consuming generation tokens.
  /// The key is sent directly to Google's official endpoint and never anywhere else.
  Future<ValidationOutcome> validateApiKey(String rawKey) async {
    final key = rawKey.trim();
    if (key.isEmpty) {
      return ValidationOutcome(
        KeyValidationResult.emptyKey,
        'API key cannot be empty. Please enter your Gemini API key.',
      );
    }

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models?key=$key',
    );

    try {
      final response = await http.get(uri).timeout(
        const Duration(seconds: 12),
      );

      if (response.statusCode == 200) {
        return ValidationOutcome(
          KeyValidationResult.valid,
          'API key verified successfully!',
        );
      } else if (response.statusCode == 400 ||
          response.statusCode == 403 ||
          response.statusCode == 401) {
        String detail = 'Google rejected the API key (HTTP ${response.statusCode}).';
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body['error'] != null && body['error']['message'] != null) {
            detail = body['error']['message'].toString();
          }
        } catch (_) {}
        return ValidationOutcome(
          KeyValidationResult.invalidKey,
          'Invalid Gemini API key: $detail',
        );
      } else {
        return ValidationOutcome(
          KeyValidationResult.serverError,
          'Google server error (HTTP ${response.statusCode}). Please try again.',
        );
      }
    } on SocketException {
      return ValidationOutcome(
        KeyValidationResult.networkError,
        'Network error: Unable to reach Google servers. Please check your internet connection.',
      );
    } on TimeoutException {
      return ValidationOutcome(
        KeyValidationResult.networkError,
        'Connection timed out while contacting Google AI. Please check your internet connection.',
      );
    } catch (e) {
      return ValidationOutcome(
        KeyValidationResult.networkError,
        'Connection error: $e',
      );
    }
  }
}
