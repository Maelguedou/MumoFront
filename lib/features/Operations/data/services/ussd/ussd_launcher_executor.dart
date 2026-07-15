import 'package:flutter/services.dart';
import 'package:ussd_launcher/ussd_launcher.dart';

import 'ussd_execution_result.dart';
import 'ussd_executor.dart';

/// Implementation de [UssdExecutor] basee sur le package ussd_launcher.
class UssdLauncherExecutor implements UssdExecutor {
  const UssdLauncherExecutor();

  @override
  Future<UssdExecutionResult> execute({
    required String code,
    required int simSlot,
    Duration? timeout,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final subscriptionId = await _subscriptionIdForSlot(simSlot);
      if (subscriptionId == null) {
        stopwatch.stop();
        return UssdExecutionResult(
          success: false,
          simSlot: simSlot,
          errorMessage:
              'Impossible de retrouver la SIM ${simSlot + 1}. Vérifiez les SIM du téléphone.',
          duration: stopwatch.elapsed,
        );
      }

      final response = await UssdLauncher.sendUssdRequest(
        ussdCode: code,
        subscriptionId: subscriptionId,
      ).timeout(timeout ?? const Duration(seconds: 25));

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
    } on PlatformException catch (error) {
      stopwatch.stop();
      return UssdExecutionResult(
        success: false,
        simSlot: simSlot,
        errorMessage: error.message ?? error.code,
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
    final simCards = await UssdLauncher.getSimCards();
    return simCards.map(_mapSimCard).whereType<DeviceSimInfo>().toList();
  }

  Future<int?> _subscriptionIdForSlot(int simSlot) async {
    final simCards = await getSimCards();
    for (final sim in simCards) {
      if (sim.slotIndex == simSlot) return sim.subscriptionId;
    }
    return null;
  }

  DeviceSimInfo? _mapSimCard(Map<String, dynamic> sim) {
    final slotIndex = _readInt(sim['slotIndex']);
    final subscriptionId = _readInt(sim['subscriptionId']);
    if (slotIndex == null) return null;

    return DeviceSimInfo(
      slotIndex: slotIndex,
      subscriptionId: subscriptionId,
      displayName: sim['displayName']?.toString(),
      carrierName: sim['carrierName']?.toString(),
      countryIso: sim['countryIso']?.toString(),
    );
  }

  int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
