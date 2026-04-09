import 'package:pdf/widgets.dart' as pw;

/// Applies a consistent scaling factor to digits in a string for PDF widgets.
const double kPdfNumericalScaleFactor = 12 / 14;

/// Builds a [pw.TextSpan] where numerical sequences are scaled down for PDF output.
pw.TextSpan buildPdfNumericalScaledSpan(String text, pw.TextStyle baseStyle) {
  final digitRegex = RegExp(r'[0-9,\.]+');
  final matches = digitRegex.allMatches(text);
  
  if (matches.isEmpty) {
    return pw.TextSpan(text: text, style: baseStyle);
  }

  final spans = <pw.TextSpan>[];
  int lastMatchEnd = 0;
  
  final scaledStyle = baseStyle.copyWith(
    fontSize: baseStyle.fontSize != null 
        ? baseStyle.fontSize! * kPdfNumericalScaleFactor 
        : null,
  );

  for (final match in matches) {
    final start = match.start;
    final end = match.end;

    if (start > lastMatchEnd) {
      spans.add(pw.TextSpan(
        text: text.substring(lastMatchEnd, start),
      ));
    }

    spans.add(pw.TextSpan(
      text: text.substring(start, end),
      style: scaledStyle,
    ));

    lastMatchEnd = end;
  }

  if (lastMatchEnd < text.length) {
    spans.add(pw.TextSpan(
      text: text.substring(lastMatchEnd),
    ));
  }

  return pw.TextSpan(children: spans, style: baseStyle);
}
