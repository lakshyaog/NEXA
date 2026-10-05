import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import 'file_storage.dart';

/// Firebase Storage implementation, guarded by `storage.rules`.
class FirebaseFileStorage implements FileStorage {
  const FirebaseFileStorage(this._storage);
  final FirebaseStorage _storage;

  @override
  Future<String> upload({
    required String path,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final task = _storage.ref(path).putFile(file);
      task.snapshotEvents.listen(
        (s) {
          if (s.totalBytes > 0) {
            onProgress?.call(s.bytesTransferred / s.totalBytes);
          }
        },
        // A failed upload surfaces on both the task and its progress stream.
        // Awaiting the task below reports it; swallowing it here keeps the
        // duplicate from escaping as an unhandled async error.
        onError: (_) {},
      );
      final snapshot = await task;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw UploadFailure(switch (e.code) {
        'unauthorized' => 'You do not have permission to upload this file.',
        'canceled' => 'Upload was canceled.',
        'retry-limit-exceeded' =>
          'Upload failed after several retries. Check your connection.',
        // Raised when no Storage bucket has been provisioned for the project,
        // which is the usual cause when the app was built without Cloudinary
        // configuration and silently fell back to Firebase Storage.
        'object-not-found' || 'bucket-not-found' =>
          'Firebase Storage is not set up for this project. Build with '
              '--dart-define-from-file=dart_define.json to upload via '
              'Cloudinary instead.',
        _ => e.message ?? 'Upload failed. Please try again.',
      });
    }
  }
}
