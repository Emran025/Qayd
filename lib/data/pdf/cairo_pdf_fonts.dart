import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// Embedded Cairo (Google Fonts OFL) for Arabic text in PDFs.
abstract final class CairoPdfFonts {
  static const _asset = 'assets/fonts/Cairo-Variable.ttf';

  static pw.Font? _font;

  static Future<pw.Font> get font async {
    if (_font != null) {
      return _font!;
    }
    final data = await rootBundle.load(_asset);
    _font = pw.Font.ttf(data);
    return _font!;
  }
}
