import 'ussd_execution_result.dart';

/// Interface metier pour executer des codes USSD sans lier le reste de
/// l'application a un package concret comme ussd_advanced_flutter ou
/// ussd_launcher.
abstract class UssdExecutor {
  /// Execute un code USSD sur une SIM donnee.
  ///
  /// [simSlot] correspond a l'emplacement de la SIM sur le telephone:
  /// 0 pour SIM 1, 1 pour SIM 2.
  Future<UssdExecutionResult> execute({
    required String code,
    required int simSlot,
    Duration? timeout,
  });

  /// Retourne les SIM disponibles sur le telephone quand le moteur USSD
  /// utilise le permet.
  Future<List<DeviceSimInfo>> getSimCards();
}
