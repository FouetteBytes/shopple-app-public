import 'dart:async';
import 'package:firebase_ai/firebase_ai.dart';

/// Thin wrapper around Firebase AI Logic Gemini access.
/// Lazily initializes to avoid startup cost if user never invokes AI.
class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();
  bool _initialized = false;
  GenerativeModel? _model;
  GenerativeModel? _liteModel; // cheaper model for low-stakes steps

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    // Basic double-checked locking
    if (!_initialized) {
      // Double-checked locking guard
      _model = FirebaseAI.vertexAI().generativeModel(model: 'gemini-2.5-flash');
      // Prefer the lite variant if available, then fall back progressively.
      try {
        _liteModel = FirebaseAI.vertexAI().generativeModel(
          model: 'gemini-2.0-flash-lite',
        );
      } catch (_) {
        try {
          _liteModel = FirebaseAI.vertexAI().generativeModel(
            model: 'gemini-2.0-flash',
          );
        } catch (_) {
          _liteModel = _model;
        }
      }
      _initialized = true;
    }
  }

  GenerativeModel get model {
    final m = _model;
    if (m == null) {
      throw StateError(
        'GeminiService not initialized. Call ensureInitialized() first.',
      );
    }
    return m;
  }

  /// Simple text generation utility.
  Future<String> generateText(
    String prompt, {
    Map<String, Object?>? safety,
    bool lite = false,
  }) async {
    await ensureInitialized();
    final m = lite ? (_liteModel ?? model) : model;
    final response = await m.generateContent([Content.text(prompt)]);
    return response.text ?? '';
  }

  /// Streaming text generation. Emits incremental text segments (joined parts may not align to word boundaries).
  Stream<String> generateTextStream(String prompt) async* {
    await ensureInitialized();
    final stream = model.generateContentStream([Content.text(prompt)]);
    await for (final event in stream) {
      final t = event.text;
      if (t != null && t.isNotEmpty) yield t;
    }
  }
}
