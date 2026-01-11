/// Central AI-related feature flags (local toggles or Remote Config wrappers later).
library;

class AIFeatureFlags {
  static bool llmParsingEnabled = true;
  static bool streamingUIEnabled =
      false; // Enables token streaming preview during parsing
  static bool functionCallingEnabled =
      false; // Placeholder for future structured tool calls
  static bool smartSuggestionsEnabled = true;
  static bool analyticsEnabled = true; // Toggle lightweight analytics emission
  static bool serverFlowEnabled =
      false; // If true, delegate runs to backend Genkit flow

  static Future<void> loadRemote() async {
    // remote config not integrated yet – future: pull values & merge.
  }
}
