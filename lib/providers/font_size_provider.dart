import 'package:flutter/material.dart';
import '../core/utils/storage.dart';

class FontSizeProvider extends ChangeNotifier {
  double _fontSizeScale = 1.0;

  double get fontSizeScale => _fontSizeScale;

  FontSizeProvider() {
    _loadFontSize();
  }

  Future<void> _loadFontSize() async {
    _fontSizeScale = await StorageHelper.getFontSizeScale();
    notifyListeners();
  }

  Future<void> setFontSizeScale(double scale) async {
    _fontSizeScale = scale;
    await StorageHelper.saveFontSizeScale(scale);
    notifyListeners();
  }
}
