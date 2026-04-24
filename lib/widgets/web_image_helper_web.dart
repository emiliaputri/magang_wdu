import 'dart:ui_web' as ui_web;
import 'dart:html' as html;

void registerWebImage(String viewId, String imageUrl, String objectFit, double borderRadius) {
  ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
    final img = html.ImageElement()
      ..src = imageUrl
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = objectFit
      ..style.borderRadius = '${borderRadius}px';
    return img;
  });
}
