import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as dev;

import '../../../../../core/logging/app_logger.dart';

class SmsLocalQueue {
  static const _key = 'pending_sms_confirmations';

  static Future<void> add(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key) ?? [];

    final normalizedPayload = Map<String, dynamic>.from(payload);
    normalizedPayload['dedupe_key'] = _dedupeKey(normalizedPayload);
    normalizedPayload['created_at'] ??= DateTime.now().toIso8601String();
    normalizedPayload['attempts'] ??= 0;

    final alreadyQueued = existing.any((raw) {
      final item = _tryDecode(raw);
      if (item == null) return false;
      return _dedupeKey(item) == normalizedPayload['dedupe_key'];
    });

    if (alreadyQueued) {
      dev.log(
        '[SmsLocalQueue] Doublon ignoré: ${normalizedPayload['dedupe_key']}',
      );
      await AppLogger.info(
        'queue duplicate ignored key=${normalizedPayload['dedupe_key']}',
        tag: 'QUEUE',
      );
      return;
    }

    existing.add(jsonEncode(normalizedPayload));
    await prefs.setStringList(_key, existing);
    dev.log('[SmsLocalQueue] Ajouté en queue. Total: ${existing.length}');
    await AppLogger.warning(
      'queue add key=${normalizedPayload['dedupe_key']} total=${existing.length}',
      tag: 'QUEUE',
    );
  }

  static Future<List<Map<String, dynamic>>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map(_tryDecode).whereType<Map<String, dynamic>>().toList();
  }

  static Future<void> removeAt(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key) ?? [];
    if (index < existing.length) {
      existing.removeAt(index);
      await prefs.setStringList(_key, existing);
      await AppLogger.info(
        'queue remove index=$index total=${existing.length}',
        tag: 'QUEUE',
      );
    }
  }

  static Future<void> updateAt(int index, Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key) ?? [];
    if (index < existing.length) {
      existing[index] = jsonEncode(payload);
      await prefs.setStringList(_key, existing);
    }
  }

  static Map<String, dynamic>? _tryDecode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (e) {
      dev.log('[SmsLocalQueue] Payload illisible ignoré: $e');
    }
    return null;
  }

  static String _dedupeKey(Map<String, dynamic> payload) {
    final transactionId = _normalize(payload['transaction_id']);
    final operator = _normalize(
      payload['operator_id'] ?? payload['operator_name'],
    );
    final amount = _normalize(payload['amount']);
    final number = _normalizePhone(payload['number']);

    if (transactionId.isNotEmpty) {
      return 'tx:$operator:$transactionId';
    }

    final smsDate = _normalize(payload['sms_date']);
    final messageHash = _hash(_normalize(payload['message']));
    return 'sms:$operator:$amount:$number:$smsDate:$messageHash';
  }

  static String _normalize(dynamic value) {
    return (value ?? '').toString().trim().toLowerCase();
  }

  static String _normalizePhone(dynamic value) {
    final digits = (value ?? '').toString().replaceAll(RegExp(r'\D+'), '');
    if (digits.startsWith('01')) return '229$digits';
    return digits;
  }

  static String _hash(String value) {
    var hash = 0;
    for (final codeUnit in value.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return hash.toRadixString(16);
  }
}
