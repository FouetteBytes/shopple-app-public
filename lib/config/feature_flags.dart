class FeatureFlags {
  // Toggle to enable fast Cloud Function search. Disable to force local-only.
  static const bool enableFastProductSearch = true;
  // Enable Firestore-backed recent search syncing
  static const bool enableCloudRecentSearchHistory = true;
  // Enable Firestore-backed recently viewed product syncing
  static const bool enableCloudRecentlyViewed = true;
  // Show Flutter performance overlay in debug builds
  static const bool showPerformanceOverlay =
      false; // set true when diagnosing jank
  // Require explicit user opt-in before first contact sync
  static const bool requireContactSyncOptIn = true;
  // Disable eager onboarding parallax image precache (useful on low-end / during perf testing)
  static const bool disableOnboardingPrecache = false;
  // Emit frame timing diagnostics to console (debug builds only recommended)
  static const bool logFrameTimings = false;
}
