/// Build-time configuration.
///
/// Values come from `--dart-define` so nothing environment-specific is baked
/// into source control. Defaults are empty, and [usesCloudinary] reports
/// whether enough was supplied to use Cloudinary; otherwise the app falls
/// back to Firebase Storage.
class AppConfig {
  static const cloudinaryCloudName =
      String.fromEnvironment('CLOUDINARY_CLOUD_NAME');

  /// An *unsigned* upload preset. Unsigned presets are designed to be used
  /// from client apps and carry no account secret, but the value is still
  /// injected at build time rather than committed.
  static const cloudinaryUploadPreset =
      String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');

  static bool get usesCloudinary =>
      cloudinaryCloudName.isNotEmpty && cloudinaryUploadPreset.isNotEmpty;
}
