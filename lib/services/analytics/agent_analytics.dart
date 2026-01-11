/// Lightweight analytics/telemetry abstraction for agent events.
/// Console logging only; extensible to Firestore/Analytics.
library;

import '../../utils/app_logger.dart';

class AgentAnalytics {
  AgentAnalytics._();
  static final AgentAnalytics instance = AgentAnalytics._();

  void record(String event, {Map<String, Object?> data = const {}}) {
    // In future: send to Firestore / Firebase Analytics respecting user privacy settings.
    // ignore: avoid_print
    if (!event.startsWith('dev_')) {
      // Suppress dev events
    }
    // Basic print (omit large payloads)
    AppLogger.d('[AgentAnalytics] $event ${data.isEmpty ? '' : data}');
  }
}
