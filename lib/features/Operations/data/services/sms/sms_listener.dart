import 'incoming_sms_message.dart';

typedef IncomingSmsCallback = void Function(IncomingSmsMessage message);

/// Interface metier pour ecouter les SMS sans lier le reste de l'application
/// a un package concret comme telephony ou another_telephony.
abstract class SmsListener {
  /// Demande les permissions necessaires a la reception/lecture SMS.
  Future<bool> requestPermissions();

  /// Demarre l'ecoute des SMS entrants.
  void listenIncomingSms({
    required IncomingSmsCallback onNewMessage,
    bool listenInBackground = true,
  });
}
