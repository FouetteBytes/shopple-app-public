import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Service for managing Firebase Remote Config feature flags and parameters
/// Used primarily for AI agent configuration and feature toggles
class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  FirebaseRemoteConfig? _remoteConfig;
  bool _initialized = false;
  final _updateController = StreamController<void>.broadcast();

  /// Stream that emits when config values are updated
  Stream<void> get onConfigUpdate => _updateController.stream;

  /// Initialize Remote Config with defaults
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      // Set config settings
      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 30),
          minimumFetchInterval: kDebugMode
              ? const Duration(minutes: 1) // Frequent updates in debug
              : const Duration(hours: 1), // Hourly in production
        ),
      );

      // Set default values
      await _remoteConfig!.setDefaults(_getDefaultConfig());

      // Fetch and activate
      await fetchAndActivate();

      _initialized = true;
      debugPrint('✅ RemoteConfigService initialized');
    } catch (e) {
      debugPrint('❌ RemoteConfigService initialization error: $e');
      rethrow;
    }
  }

  /// Fetch latest config from Firebase and activate
  Future<bool> fetchAndActivate() async {
    if (_remoteConfig == null) {
      await initialize();
    }

    try {
      final updated = await _remoteConfig!.fetchAndActivate();
      if (updated) {
        _updateController.add(null);
        debugPrint('🔄 Remote Config updated and activated');
      }
      return updated;
    } catch (e) {
      debugPrint('⚠️ Remote Config fetch error: $e');
      return false;
    }
  }

  /// Get all default configuration values
  Map<String, dynamic> _getDefaultConfig() {
    return {
      // 🤖 AI Shopping Agent - Master Feature Flags
      'ai_shopping_agent_enabled': true,
      'ai_voice_assistant_enabled': false,
      'ai_price_predictor_enabled': false,
      'ai_smart_categorization_enabled': false,
      'ai_recipe_suggestions_enabled': false,
    };
  }

  // ==================== AI Feature Flags ====================

  /// Main AI Shopping Agent (chat assistant, product suggestions)
  bool get aiShoppingAgentEnabled => _getBool('ai_shopping_agent_enabled');

  /// AI Voice Assistant (voice commands, speech-to-text)
  bool get aiVoiceAssistantEnabled => _getBool('ai_voice_assistant_enabled');

  /// AI Price Predictor (price trends, best time to buy)
  bool get aiPricePredictorEnabled => _getBool('ai_price_predictor_enabled');

  /// AI Smart Categorization (auto-categorize products)
  bool get aiSmartCategorizationEnabled =>
      _getBool('ai_smart_categorization_enabled');

  /// AI Recipe Suggestions (meal planning, ingredient lists)
  bool get aiRecipeSuggestionsEnabled =>
      _getBool('ai_recipe_suggestions_enabled');

  // ==================== Helper Methods ====================

  bool _getBool(String key) {
    try {
      return _remoteConfig?.getBool(key) ?? _getDefaultConfig()[key] as bool;
    } catch (e) {
      debugPrint('⚠️ Error getting bool $key: $e');
      return _getDefaultConfig()[key] as bool? ?? false;
    }
  }

  /// Get all current config values (for debugging)
  Map<String, dynamic> getAllValues() {
    if (_remoteConfig == null) return _getDefaultConfig();

    final values = <String, dynamic>{};
    for (var key in _remoteConfig!.getAll().keys) {
      values[key] = _remoteConfig!.getValue(key).asString();
    }
    return values;
  }

  /// Dispose resources
  void dispose() {
    _updateController.close();
  }
}
