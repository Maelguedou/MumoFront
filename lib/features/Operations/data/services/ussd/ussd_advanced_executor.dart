import 'package:ussd_advanced_flutter/ussd_advanced_flutter.dart';

import 'ussd_execution_result.dart';
import 'ussd_executor.dart';

/// Implementation de [UssdExecutor] basee sur le package actuel
/// ussd_advanced_flutter.
///
/// Cette classe garde le comportement existant, mais le cache derriere notre
/// interface metier pour faciliter une migration future vers un autre moteur.
class UssdAdvancedExecutor implements UssdExecutor {
  const UssdAdvancedExecutor();

  @override
  Future<UssdExecutionResult> execute({
    required String code,
    required int simSlot,
    Duration? timeout,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final response = await UssdAdvancedFlutter.sendUssdForResponse(
        code,
        simSlot: simSlot,
        timeout: timeout ?? const Duration(seconds: 25),
      );

      stopwatch.stop();

      final message = response?.trim();
      return UssdExecutionResult(
        success: message != null && message.isNotEmpty,
        simSlot: simSlot,
        rawMessage: response,
        errorMessage: message == null || message.isEmpty
            ? 'Aucune reponse USSD capturee.'
            : null,
        duration: stopwatch.elapsed,
      );
    } catch (error) {
      stopwatch.stop();

      return UssdExecutionResult(
        success: false,
        simSlot: simSlot,
        errorMessage: error.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }

  @override
  Future<List<DeviceSimInfo>> getSimCards() async {
    // ussd_advanced_flutter execute sur simSlot, mais ne fournit pas d'API
    // fiable pour lister les SIM disponibles.
    return const [];
  }
}
