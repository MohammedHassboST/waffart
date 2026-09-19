class CdnImageHelper {
  /// توليد رابط CDN مع تحويلات Supabase Storage
  /// يقلل حجم الصورة بنسبة 70-90% حسب الإعدادات
  static String transform(
      String url, {
        int? width,
        int? height,
        int quality = 75,
        String resize = 'cover',
        String format = 'webp',
      }) {
    if (url.isEmpty) return url;
    // إذا كان الرابط خارجي، أرجعه كما هو
    if (!url.contains('supabase.co/storage')) return url;

    final params = <String, String>{
      'quality': quality.toString(),
      'format': format,
      'resize': resize,
    };
    if (width != null) params['width'] = width.toString();
    if (height != null) params['height'] = height.toString();

    final separator = url.contains('?') ? '&' : '?';
    final query = params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');

    return '$url$separator$query';
  }

  // أحجام جاهزة
  static String thumbnail(String url) =>
      transform(url, width: 200, height: 200, quality: 60);
  static String card(String url) =>
      transform(url, width: 600, quality: 75);
  static String detail(String url) =>
      transform(url, width: 1200, quality: 85);
  static String hero(String url) =>
      transform(url, width: 1600, quality: 90);
}