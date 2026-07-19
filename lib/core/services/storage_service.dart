import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static final _storage = FirebaseStorage.instance;

  /// Uploads raw bytes (works identically on Android and Web via file_picker's
  /// withData: true) and returns (storagePath, downloadUrl).
  static Future<(String, String)> uploadBytes({
    required String path,
    required Uint8List bytes,
    String contentType = 'application/octet-stream',
  }) async {
    final ref = _storage.ref(path);
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    final url = await ref.getDownloadURL();
    return (path, url);
  }

  static Future<String> downloadUrl(String path) =>
      _storage.ref(path).getDownloadURL();
}
