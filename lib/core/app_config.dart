/// Build-time configuration for the upload backend.
///
/// The defaults below are the evaluation project's Cloudinary settings, so a
/// fresh clone uploads correctly without any extra build flags. Both values
/// are safe to keep in source: a cloud name is public, and an *unsigned*
/// upload preset is designed to be embedded in client applications. Neither
/// grants read access to the account, and neither is an API secret — the
/// signing key is never shipped to the client.
///
/// Either value can still be overridden per build:
///
/// ```sh
/// flutter build apk --release --dart-define-from-file=dart_define.json
/// ```
///
/// Clearing them (passing an empty string) makes [usesCloudinary] false, and
/// the app falls back to Firebase Storage, whose rules ship in the
/// repository as `storage.rules`.
class AppConfig {
  static const cloudinaryCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'u3gjtk1b',
  );

  static const cloudinaryUploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'nexa_unsigned',
  );

  /// Whether enough configuration exists to upload through Cloudinary.
  static bool get usesCloudinary =>
      cloudinaryCloudName.isNotEmpty && cloudinaryUploadPreset.isNotEmpty;
}
