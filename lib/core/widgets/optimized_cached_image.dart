import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Optimized cached image widget with performance improvements
class OptimizedCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool fadeInImage;
  final Duration fadeInDuration;
  final bool memCacheEnabled;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const OptimizedCachedImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.fadeInImage = true,
    this.fadeInDuration = const Duration(milliseconds: 200),
    this.memCacheEnabled = true,
    this.memCacheWidth,
    this.memCacheHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildErrorWidget();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheEnabled ? (memCacheWidth ?? 200) : null,
      memCacheHeight: memCacheEnabled ? (memCacheHeight ?? 200) : null,
      placeholder: placeholder != null
          ? (context, url) => placeholder!
          : (context, url) => _buildPlaceholder(),
      errorWidget: errorWidget != null
          ? (context, url, error) => errorWidget!
          : (context, url, error) => _buildErrorWidget(),
      fadeInDuration: fadeInImage ? fadeInDuration : Duration.zero,
      useOldImageOnUrlChange: true, // Improves performance during URL changes
      maxWidthDiskCache: 800, // Limit disk cache size
      maxHeightDiskCache: 800,
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Material(
      color: const Color(0xFF2C3E50),
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          color: Colors.white,
          size: 40.sp,
        ),
      ),
    );
  }
}

/// Optimized avatar widget with performance improvements
class OptimizedAvatarImage extends StatelessWidget {
  final String imageUrl;
  final double size;
  final String fallbackText;
  final Color? backgroundColor;
  final Color? textColor;

  const OptimizedAvatarImage({
    Key? key,
    required this.imageUrl,
    required this.size,
    required this.fallbackText,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? Colors.grey.shade400,
      ),
      child: ClipOval(
        child: imageUrl.isNotEmpty
            ? OptimizedCachedImage(
                imageUrl: imageUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                memCacheWidth: (size * 2).toInt(),
                memCacheHeight: (size * 2).toInt(),
                errorWidget: _buildFallback(),
                placeholder: _buildFallback(),
              )
            : _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: size,
      height: size,
      color: backgroundColor ?? Colors.grey.shade400,
      child: Center(
        child: Text(
          fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: textColor ?? Colors.white,
          ),
        ),
      ),
    );
  }
}
