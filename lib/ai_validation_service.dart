@JS()
library web_interop;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;

@JS('webllm_chat')
external Object _webllmChat(String userText, String targetText);

@JS('is_webllm_ready')
external bool _isWebLLMReady();

class AiValidationService {
  bool _isInitialized = false;
  bool _isInitializing = false;

  bool get isInitializing => _isInitializing;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;
    _isInitializing = true;

    try {
      if (kIsWeb) {
        int attempts = 0;
        while (attempts < 60) {
          try {
            if (_isWebLLMReady()) break;
          } catch (_) {}
          await Future.delayed(const Duration(seconds: 2));
          attempts++;
        }
      }
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
    } finally {
      _isInitializing = false;
    }
  }

  Future<ValidationResult> validateTranslation({
    required String originalText,
    required String userTranslation,
    required String correctTranslation,
    required String learningLanguage,
    required String translationLanguage,
  }) async {
    if (!_isInitialized) {
      return ValidationResult(
        isValid: false,
        confidence: 0.0,
        feedback: "AI not ready",
      );
    }

    try {
      final response = await _callWebLLM(userTranslation, correctTranslation);
      final normalized = response.toUpperCase();
      final isValid = normalized.contains("YES");

      return ValidationResult(
        isValid: isValid,
        confidence: 0.8,
        feedback: response,
      );
    } catch (e) {
      return ValidationResult(
        isValid: false,
        confidence: 0.0,
        feedback: "AI error: $e",
      );
    }
  }

  Future<String> _callWebLLM(String userText, String targetText) async {
    try {
      final Object promise = _webllmChat(userText, targetText);
      final dynamic result = await js_util.promiseToFuture(promise);
      return result?.toString() ?? "No response";
    } catch (e) {
      return "JS call failed: $e";
    }
  }

  void dispose() {
    _isInitialized = false;
  }
}

class ValidationResult {
  final bool isValid;
  final double confidence;
  final String? feedback;

  ValidationResult({
    required this.isValid,
    required this.confidence,
    this.feedback,
  });
}