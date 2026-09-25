import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ui';
import 'sms_local_queue.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '../../../../../core/logging/app_logger.dart';
import 'background_retry_service.dart';

const _smsBackgroundServiceInterval = Duration(minutes: 15);

Future<void> initializeSmsBackgroundService() async {
  final service = FlutterBackgroundService();
  await AppLogger.info('configure background service', tag: 'BG_SERVICE');

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: smsBackgroundServiceOnStart,
      autoStart: false,
      autoStartOnBoot: false,
      isForegroundMode: true,
      initialNotificationTitle: 'Mumo Agent',
      initialNotificationContent:
          'Synchronisation des confirmations en attente',
      foregroundServiceNotificationId: 4401,
      foregroundServiceTypes: [AndroidForegroundType.dataSync],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: smsBackgroundServiceOnStart,
      onBackground: smsBackgroundServiceOnIosBackground,
    ),
  );
  await AppLogger.info('background service configured', tag: 'BG_SERVICE');
}

@pragma('vm:entry-point')
Future<bool> smsBackgroundServiceOnIosBackground(
  ServiceInstance service,
) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  await BackgroundRetryService.retryPending(force: true);
  final pendingAfterStartup = await SmsLocalQueue.getAll();

  if (pendingAfterStartup.isEmpty) {
    service.stopSelf();
    return true;
  }

  await AppLogger.info('iOS background retry executed', tag: 'BG_SERVICE');
  return true;
}

@pragma('vm:entry-point')
void smsBackgroundServiceOnStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  await AppLogger.info('background service started', tag: 'BG_SERVICE');

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  await BackgroundRetryService.retryPending(force: true);

  final pendingAfterStartup = await SmsLocalQueue.getAll();
  if (pendingAfterStartup.isEmpty) {
    service.stopSelf();
    return;
  }

  Timer.periodic(_smsBackgroundServiceInterval, (timer) async {
    final isServiceRunning = await _isServiceRunning(service);
    if (!isServiceRunning) {
      timer.cancel();
      return;
    }

    dev.log('[BG Service] Retry périodique de la queue SMS');
    await AppLogger.info(
      'background service periodic retry',
      tag: 'BG_SERVICE',
    );
    await BackgroundRetryService.retryPending();

    final pendingAfterRetry = await SmsLocalQueue.getAll();

    if (pendingAfterRetry.isEmpty) {
      timer.cancel();
      service.stopSelf();
      return;
    }
  });
}

Future<bool> _isServiceRunning(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    return service.isForegroundService();
  }

  return true;
}

Future<void> startSmsBackgroundServiceIfNeeded() async {
  final pending = await SmsLocalQueue.getAll();

  if (pending.isEmpty) {
    return;
  }

  final service = FlutterBackgroundService();
  await service.startService();
}
