import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Voice input/output service for PRAVIN
/// Integrates speech-to-text and text-to-speech capabilities
class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isListening = false;
  String _capturedText = '';

  ValueChanged<String>? onTextCaptured;
  ValueChanged<String>? onSpeakingStarted;
  ValueChanged<String>? onSpeakingCompleted;

  VoiceService();

  /// Initialize voice services
  Future<void> initialize() async {
    final available = await _speechToText.initialize();
    if (available) {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
    }
  }

  /// Start voice input for capturing speech
  Future<void> startListening() async {
    if (!_isListening) {
      _isListening = true;
      await _speechToText.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            _capturedText = result.recognizedWords;
            if (onTextCaptured != null) {
              onTextCaptured!(capturedText);
            }
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        localeId: 'en_US',
      );
    }
  }

  /// Stop voice input
  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
    }
  }

  /// Speak text aloud
  Future<void> speak(String text) async {
    if (onSpeakingStarted != null) {
      onSpeakingStarted!(text);
    }
    await _flutterTts.speak(text);
    if (onSpeakingCompleted != null) {
      onSpeakingCompleted!(text);
    }
  }

  /// Clear captured text
  void clearText() {
    _capturedText = '';
  }

  /// Get current captured text
  String get capturedText => _capturedText;

  /// Check if voice input is active
  bool get isListening => _isListening;
}