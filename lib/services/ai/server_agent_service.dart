import 'package:cloud_functions/cloud_functions.dart';

/// Thin wrapper to call the backend shoppingAgentFlow (Genkit flow via callable function).
/// Feature gated by AIFeatureFlags.serverFlowEnabled.
class ServerAgentService {
  ServerAgentService._();
  static final instance = ServerAgentService._();

  final _functions = FirebaseFunctions.instanceFor(region: 'asia-south1');

  Future<Map<String, dynamic>> runShoppingAgent({
    required String userInput,
    bool dryRun = false,
  }) async {
    final callable = _functions.httpsCallable('shoppingAgentFlow');
    final resp = await callable.call({
      'userInput': userInput,
      'dryRun': dryRun,
    });
    final data = resp.data as Map<String, dynamic>;
    final result = data['result'] as Map<String, dynamic>? ?? data;
    if (data['runId'] != null && result['runId'] == null) {
      result['runId'] = data['runId'];
    }
    if (data['quota'] != null && result['quota'] == null) {
      result['quota'] = data['quota'];
    }
    return result;
  }
}
