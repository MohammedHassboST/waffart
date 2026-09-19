class ImageUrlHelper {
  /// يحول رابط صورة Supabase Storage إلى thumbnail محسّن
  /// يقلل حجم الصورة بنسبة 70% مع الحفاظ على الجودة
  static String thumbnail(String url, {int width = 400, int quality = 75}) {
    if (!url.contains('supabase.co/storage')) return url;
    // Supabase Storage Transformation
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}width=$width&quality=$quality&resize=contain';
  }
}