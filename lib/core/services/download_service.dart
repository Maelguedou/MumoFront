import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

class DownloadService {
  DownloadService._();

  /// Laisse l'utilisateur choisir où enregistrer le fichier
  /// via le sélecteur natif (Storage Access Framework sur Android).
  ///
  /// Retourne le chemin choisi si succès, `null` si l'utilisateur annule.
  static Future<String?> saveToDownloads({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    final extension = fileName.contains('.') ? fileName.split('.').last : null;

    final String? savedPath = await FilePicker.saveFile(
      dialogTitle: 'Enregistrer le fichier',
      fileName: fileName,
      type: extension != null ? FileType.custom : FileType.any,
      allowedExtensions: extension != null ? [extension] : null,
      bytes: bytes,
    );

    return savedPath;
  }
}