import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AppNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double? borderRadius;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
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

    Widget image = CachedNetworkImage(
      imageUrl: optimizedUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        ),
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
        color: Colors.grey.shade200,
        borderRadius: borderRadius != null ? BorderRadius.circular(borderRadius!) : null,
      ),
      child: const Center(
        child: Icon(
          Icons.broken_image_rounded,
          color: Colors.grey,
        ),
      ),
    );
  }
}
