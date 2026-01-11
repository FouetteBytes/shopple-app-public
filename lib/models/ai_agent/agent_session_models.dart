import 'package:shopple/models/ai_agent/agent_function_calls.dart';
import 'package:shopple/models/ai_agent/agent_intents.dart';

class AgentExecutionSession {
  AgentExecutionSession({
    required this.input,
    required this.parsed,
    required this.plan,
    required this.currentIndex,
    required this.added,
    required this.failures,
  });
  final String input;
  final AgentParsedCommand parsed;
  final AgentExecutionPlan plan;
  int currentIndex;
  bool completed = false;
  String? listId;
  final Map<String, String> added;
  final Map<String, String> failures;
}

class AgentStepResult {
  final int stepIndex;
  final int totalSteps;
  final Map<String, String> added;
  final Map<String, String> failures;
  final bool completed;
  AgentStepResult({
    required this.stepIndex,
    required this.totalSteps,
    required this.added,
    required this.failures,
    required this.completed,
  });
}
