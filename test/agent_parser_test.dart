import 'package:flutter_test/flutter_test.dart';
import 'package:shopple/models/ai_agent/agent_intents.dart';

void main() {
  group('AgentCommandParser', () {
    test('parses create list with items', () {
      final input =
          'Create a new list called dinner and add a meat type and coca cola';
      final parsed = AgentCommandParser.parse(input);
      expect(parsed.createListRequested, true);
      expect(parsed.listName, 'Dinner');
      expect(parsed.rawItemPhrases.length, 2);
      expect(parsed.rawItemPhrases[0].toLowerCase().contains('meat'), true);
      expect(parsed.rawItemPhrases[1].toLowerCase().contains('coca'), true);
    });

    test('handles list named pattern', () {
      final input = 'Please create list named groceries and add milk, bread';
      final parsed = AgentCommandParser.parse(input);
      expect(parsed.listName, 'Groceries');
      expect(parsed.rawItemPhrases.length, 2);
    });

    test('fallback list name sanitization', () {
      final input = 'create list called the test list and add apples';
      final parsed = AgentCommandParser.parse(input);
      expect(parsed.listName, 'Test'); // trimmed redundant words
    });
  });
}
