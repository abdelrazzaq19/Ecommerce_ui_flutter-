/// Static facts about the build.
abstract final class AppInfo {
  /// Keep in step with `version:` in pubspec.yaml. A `package_info_plus`
  /// dependency would read it automatically, which is not worth a plugin for a
  /// single line of text.
  static const String version = '1.0.0';
}
