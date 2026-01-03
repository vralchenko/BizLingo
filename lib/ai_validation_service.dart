@JS()
library web_interop;

import 'dart:async';
import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;

@JS('webllm_validate')
external Object _webllmValidate(String userText, String targetText);
@JS('is_webllm_ready')
external bool _isWebLLMReady();

class ValidationResult {
  final bool isValid;
  final String reason;
  ValidationResult(this.isValid, this.reason);
}

class AiValidationService {
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    while (true) {
      try { if (_isWebLLMReady()) { _isInitialized = true; return; } } catch (_) {}
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  Future<ValidationResult> detailedValidate(String user, String target) async {
    final cleanUser = user.trim().toLowerCase();
    final cleanTarget = target.trim().toLowerCase();

    if (cleanUser == cleanTarget) {
      return ValidationResult(true, "Exact match found.");
    }

    try {
      final promise = _webllmValidate(user, target);
      final response = await js_util.promiseToFuture(promise);
      final String aiText = response.toString();

      bool isYes = aiText.toUpperCase().contains("YES");
      String explanation = aiText;
      if (aiText.toLowerCase().contains("reason:")) {
        explanation = aiText.substring(aiText.toLowerCase().indexOf("reason:") + 7).trim();
      }

      return ValidationResult(isYes, explanation);
    } catch (e) {
      return ValidationResult(false, "Validation error: $e");
    }
  }
}