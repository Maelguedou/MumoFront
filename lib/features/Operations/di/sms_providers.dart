import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/sms/sms_listener.dart';
import '../data/services/sms/telephony_sms_listener.dart';
import '../data/services/sms_service.dart';

final smsListenerProvider = Provider<SmsListener>((ref) {
  return TelephonySmsListener();
});

final smsServiceProvider = Provider<SmsService>((ref) {
  final service = SmsService(ref, ref.read(smsListenerProvider));
  ref.onDispose(service.dispose);
  return service;
});
