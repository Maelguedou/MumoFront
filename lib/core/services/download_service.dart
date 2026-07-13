import 'package:flutter/services.dart';

class DownloadService {
  DownloadService._();

  static const MethodChannel _channel = MethodChannel('mumo_agent/downloads');

  static Future<String?> saveToDownloads({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) {
    return _channel.invokeMethod<String>('saveFileToDownloads', {
      'bytes': bytes,
      'fileName': fileName,
      'mimeType': mimeType,
    });
  }
}
