import '../config/app_config.dart';

/// Resolves backend-relative URLs (e.g. `/uploads/products/x.png`) against
/// the API origin. Absolute URLs (Cloudinary etc.) pass through unchanged.
String resolveApiUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  final apiV1 = AppConfig.baseUrl.indexOf('/api/v1');
  final origin = apiV1 > 0
      ? AppConfig.baseUrl.substring(0, apiV1)
      : AppConfig.baseUrl;
  return trimmed.startsWith('/') ? '$origin$trimmed' : '$origin/$trimmed';
}