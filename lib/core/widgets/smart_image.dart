import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../image/cdn_image_helper.dart';

enum ImageSize { thumbnail, card, detail, hero }

class SmartImage extends StatelessWidget {
  final String url;
  final ImageSize size;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const SmartImage({
    super.key,
    required this.url,
    this.size = ImageSize.card,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  String _resolveUrl() {
    switch (size) {
      case ImageSize.thumbnail:
        return CdnImageHelper.thumbnail(url);
      case ImageSize.card:
        return CdnImageHelper.card(url);
      case ImageSize.detail:
        return CdnImageHelper.detail(url);
      case ImageSize.hero:
        return CdnImageHelper.hero(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget image = url.isEmpty
        ? _placeholder(icon: Icons.image_not_supported)
        : CachedNetworkImage(
      imageUrl: _resolveUrl(),
      width: width,
      height: height,
      fit: fit,
      // تخزين مؤقت دائم
      cacheKey: _resolveUrl(),
      memCacheWidth: width != null ? (width! * 2).toInt() : null,
      memCacheHeight: height != null ? (height! * 2).toInt() : null,
      maxWidthDiskCache: 1200,
      maxHeightDiskCache: 1200,
      placeholder: (_, _) => _placeholder(),
      errorWidget: (_, _, _) =>
          _placeholder(icon: Icons.broken_image),
      fadeInDuration: const Duration(milliseconds: 250),
      fadeOutDuration: const Duration(milliseconds: 100),
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  Widget _placeholder({IconData? icon}) {
    if (icon != null) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: Icon(icon, color: Colors.grey, size: 40),
      );
    }
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(width: width, height: height, color: Colors.white),
    );
  }
}