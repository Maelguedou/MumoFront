/// Resultat normalise d'une execution USSD.
///
/// Le but est d'avoir une sortie stable pour le controller, peu importe le
/// package utilise derriere.
class UssdExecutionResult {
  const UssdExecutionResult({
    required this.success,
    required this.simSlot,
    this.rawMessage,
    this.errorMessage,
    this.duration,
  });

  final bool success;
  final int simSlot;
  final String? rawMessage;
  final String? errorMessage;
  final Duration? duration;

  bool get hasMessage => rawMessage != null && rawMessage!.trim().isNotEmpty;
}

/// Informations normalisees sur une SIM presente dans le telephone.
class DeviceSimInfo {
  const DeviceSimInfo({
    required this.slotIndex,
    this.subscriptionId,
    this.displayName,
    this.carrierName,
    this.countryIso,
  });

  final int slotIndex;
  final int? subscriptionId;
  final String? displayName;
  final String? carrierName;
  final String? countryIso;

  String get label {
    final name = carrierName ?? displayName;
    if (name == null || name.trim().isEmpty) {
      return 'SIM ${slotIndex + 1}';
    }

    return 'SIM ${slotIndex + 1} - $name';
  }
}
