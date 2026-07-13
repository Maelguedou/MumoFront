import 'package:telephony/telephony.dart';

import '../sms_service.dart' show backGroundMessageHandler;
import 'incoming_sms_message.dart';
import 'sms_listener.dart';

/// Implementation actuelle de [SmsListener] basee sur le package telephony.
class TelephonySmsListener implements SmsListener {
  TelephonySmsListener({Telephony? telephony})
    : _telephony = telephony ?? Telephony.instance;

  final Telephony _telephony;

  @override
  Future<bool> requestPermissions() async {
    final granted = await _telephony.requestPhoneAndSmsPermissions;
    return granted == true;
  }

  @override
  void listenIncomingSms({
    required IncomingSmsCallback onNewMessage,
    bool listenInBackground = true,
  }) {
    _telephony.listenIncomingSms(
      onNewMessage: (message) {
        onNewMessage(_mapMessage(message));
      },
      onBackgroundMessage: backGroundMessageHandler,
      listenInBackground: listenInBackground,
    );
  }

  IncomingSmsMessage _mapMessage(SmsMessage message) {
    return IncomingSmsMessage(
      body: message.body,
      sender: message.address ?? '',
      receivedAt: DateTime.fromMillisecondsSinceEpoch(
        message.date ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}
