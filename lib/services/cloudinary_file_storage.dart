import 'dart:io';

import 'package:dio/dio.dart';

import '../core/app_config.dart';
import 'file_storage.dart';

/// Cloudinary implementation using an unsigned upload preset.
///
/// Used because enabling Firebase Storage requires a billed Cloud project.
/// The logical [path] is mapped to a Cloudinary folder plus public id so the
/// stored layout matches what the Firebase rules describe.
class CloudinaryFileStorage implements FileStorage {
  CloudinaryFileStorage(this._dio);
  final Dio _dio;

  @override
  Future<String> upload({
    required String path,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    if (!AppConfig.usesCloudinary) {
      throw const UploadFailure(
        'Uploads are not configured. Build with --dart-define for '
        'CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET.',
      );
    }

    final segments = path.split('/');
    final fileName = segments.removeLast();
    final folder = segments.join('/');

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'https://api.cloudinary.com/v1_1/'
        '${AppConfig.cloudinaryCloudName}/image/upload',
        data: FormData.fromMap({
          'file': await MultipartFile.fromFile(file.path, filename: fileName),
          'upload_preset': AppConfig.cloudinaryUploadPreset,
          'folder': folder,
        }),
        onSendProgress: (sent, total) {
          if (total > 0) onProgress?.call(sent / total);
        },
      );

      final url = response.data?['secure_url'];
      if (url is! String) {
        throw const UploadFailure('Upload succeeded but no URL was returned.');
      }
      return url;
    } on DioException catch (e) {
      throw UploadFailure(switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          'Upload timed out. Check your connection and retry.',
        DioExceptionType.connectionError =>
          'No internet connection. Check your network and retry.',
        _ => _messageFrom(e),
      });
    }
  }

  String _messageFrom(DioException e) {
    final body = e.response?.data;
    if (body is Map && body['error'] is Map) {
      final detail = body['error']['message'];
      if (detail is String) return 'Upload rejected: $detail';
    }
    return 'Upload failed. Please try again.';
  }
}
