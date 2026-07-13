import 'dart:developer' as dev;

import 'package:shared_preferences/shared_preferences.dart';

class AppLogger {
  static const _key = 'app_debug_logs';
  static const _maxEntries = 1000;

  static Future<void> info(String message, {String tag = 'APP'}) {
    return _write('INFO', tag, message);
  }

  static Future<void> warning(String message, {String tag = 'APP'}) {
    return _write('WARN', tag, message);
  }

  static Future<void> error(
    String message, {
    String tag = 'APP',
    Object? error,
    StackTrace? stackTrace,
  }) {
    final details = [
      message,
      if (error != null) 'error=$error',
      if (stackTrace != null) 'stack=$stackTrace',
    ].join(' | ');

    return _write('ERROR', tag, details);
  }

  static Future<List<String>> getLogs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<String> dump() async {
    final logs = await getLogs();
    if (logs.isEmpty) return 'Aucun log disponible.';
    return logs.join('\n');
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<void> _write(String level, String tag, String message) async {
    final line = '${DateTime.now().toIso8601String()} [$level][$tag] $message';
    dev.log(line, name: tag);

    try {
      final prefs = await SharedPreferences.getInstance();
      final logs = prefs.getStringList(_key) ?? [];
      logs.add(line);

      final overflow = logs.length - _maxEntries;
      if (overflow > 0) {
        logs.removeRange(0, overflow);
      }

      await prefs.setStringList(_key, logs);
    } catch (e) {
      dev.log('Unable to persist log: $e', name: 'AppLogger');
    }
  }
}
