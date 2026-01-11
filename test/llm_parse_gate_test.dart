import 'package:flutter_test/flutter_test.dart';
import 'package:shopple/config/feature_flags_ai.dart';
import 'package:shopple/models/ai_agent/agent_intents.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('LLM parse gating', () {
    test('disables LLM path when flag off', () async {
      AIFeatureFlags.llmParsingEnabled = false;
      final parsed = AgentCommandParser.parse(
        'Create a list called dinner and add coca cola',
      );
      expect(parsed.listName?.toLowerCase(), contains('dinner'));
      expect(parsed.rawItemPhrases, isNotEmpty);
    });
  });
}
