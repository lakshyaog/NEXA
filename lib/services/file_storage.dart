import 'dart:io';

/// Thrown with a user-presentable message.
class UploadFailure implements Exception {
  const UploadFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Uploads binary files and returns a public URL.
///
/// The app talks only to this interface, so the backing provider (Firebase
/// Storage or Cloudinary) can change without touching any screen.
abstract interface class FileStorage {
  /// Uploads [file] under a logical [path] such as `customers/<id>/id.jpg`,
  /// reporting fractional progress through [onProgress].
  Future<String> upload({
    required String path,
    required File file,
    void Function(double progress)? onProgress,
  });
}
