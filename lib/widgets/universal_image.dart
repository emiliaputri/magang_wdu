import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;

class UniversalImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final double borderRadius;

  const UniversalImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // For Web, use an HTML <img> tag to bypass CanvasKit/Skia CORS restrictions
      final String viewId = 'img-${imageUrl.hashCode}';
      
      // Register the view factory for this specific image
      ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
        final img = html.ImageElement()
          ..src = imageUrl
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = _getHtmlObjectFit(fit)
          ..style.borderRadius = '${borderRadius}px';
        return img;
      });

      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox(
          width: width,
          height: height,
          child: HtmlElementView(viewType: viewId),
        ),
      );
    } else {
      // For Mobile, use CachedNetworkImage
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: width,
          height: height,
          fit: fit,
          placeholder: (context, url) => placeholder ?? _defaultPlaceholder(),
          errorWidget: (context, url, error) => errorWidget ?? _defaultErrorWidget(),
        ),
      );
    }
  }

  String _getHtmlObjectFit(BoxFit fit) {
    switch (fit) {
      case BoxFit.cover: return 'cover';
      case BoxFit.contain: return 'contain';
      case BoxFit.fill: return 'fill';
      case BoxFit.fitWidth: return 'contain';
      case BoxFit.fitHeight: return 'contain';
      case BoxFit.none: return 'none';
      case BoxFit.scaleDown: return 'scale-down';
    }
  }

  Widget _defaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _defaultErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Icon(Icons.error_outline, color: Colors.grey),
    );
  }
}
