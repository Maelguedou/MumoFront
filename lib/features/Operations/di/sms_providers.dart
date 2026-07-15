import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/sms/another_telephony_sms_listener.dart';
import '../data/services/sms/sms_listener.dart';
import '../data/services/sms_service.dart';

final smsListenerProvider = Provider<SmsListener>((ref) {
  return AnotherTelephonySmsListener();
});

final smsServiceProvider = Provider<SmsService>((ref) {
  final service = SmsService(ref, ref.read(smsListenerProvider));
  ref.onDispose(service.dispose);
  return service;
});
