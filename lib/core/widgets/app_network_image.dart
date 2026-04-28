import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/brand_tokens.dart';

class AppNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double? borderRadius;

  /// Optional explicit memory-cache width in physical pixels.
  /// Falls back to `width * MediaQuery.devicePixelRatio` when null.
  final int? memCacheWidth;
  final int? memCacheHeight;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  String _optimizeCloudinaryUrl(String url) {
    if (url.contains('cloudinary.com') && url.contains('/upload/')) {
      if (!url.contains('/upload/w_') && !url.contains('/upload/h_')) {
        return url.replaceFirst('/upload/', '/upload/w_300,h_300,c_fill/');
      }
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    final optimizedUrl = _optimizeCloudinaryUrl(imageUrl!);
    final dpr = MediaQuery.of(context).devicePixelRatio;

    final effectiveMemW = memCacheWidth ??
        (width != null ? (width! * dpr).round() : null);
    final effectiveMemH = memCacheHeight ??
        (height != null ? (height! * dpr).round() : null);

    Widget image = CachedNetworkImage(
      imageUrl: optimizedUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: effectiveMemW,
      memCacheHeight: effectiveMemH,
      fadeInDuration: const Duration(milliseconds: 120),
      fadeOutDuration: Duration.zero,
      placeholder: (context, url) => _ShimmerPlaceholder(
        width: width,
        height: height,
        borderRadius: borderRadius,
      ),
      errorWidget: (context, url, error) => _buildPlaceholder(),
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius!),
        child: image,
      );
    }

    return image;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: BrandTokens.bgSoft,
        borderRadius: borderRadius != null ? BorderRadius.circular(borderRadius!) : null,
      ),
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          color: BrandTokens.borderSoft,
        ),
      ),
    );
  }
}

class _ShimmerPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final double? borderRadius;
  const _ShimmerPlaceholder({this.width, this.height, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: BrandTokens.bgSoft,
        borderRadius: borderRadius != null
            ? BorderRadius.circular(borderRadius!)
            : null,
      ),
    );
  }
}
