import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
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
      final hasPhonePermission = await _ensurePhonePermission();
      if (!hasPhonePermission) {
        stopwatch.stop();
        return UssdExecutionResult(
          success: false,
          simSlot: simSlot,
          errorMessage:
              'Permission téléphone refusée. Autorisez les appels pour lancer le code USSD.',
          duration: stopwatch.elapsed,
        );
      }

      final simCards = await getSimCards();
      final shouldValidateSim = simCards.isNotEmpty;
      final selectedSimExists = simCards.any((sim) => sim.slotIndex == simSlot);
      if (shouldValidateSim && !selectedSimExists) {
        stopwatch.stop();
        return UssdExecutionResult(
          success: false,
          simSlot: simSlot,
          errorMessage:
              'Impossible de retrouver la SIM ${simSlot + 1}. Vérifiez les SIM du téléphone.',
          duration: stopwatch.elapsed,
        );
      }

      return _launchManualUssdCall(
        code: code,
        simSlot: simSlot,
        stopwatch: stopwatch,
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

  Future<bool> _ensurePhonePermission() async {
    final status = await Permission.phone.status;
    if (status.isGranted) return true;

    final requested = await Permission.phone.request();
    return requested.isGranted;
  }

  Future<UssdExecutionResult> _launchManualUssdCall({
    required String code,
    required int simSlot,
    required Stopwatch stopwatch,
  }) async {
    try {
      await UssdLauncher.launchUssdCall(
        code: code,
        slotIndex: simSlot,
      );

      stopwatch.stop();
      return UssdExecutionResult(
        success: true,
        simSlot: simSlot,
        errorMessage: 'USSD lance en mode manuel.',
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
