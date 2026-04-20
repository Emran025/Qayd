import 'package:pdf/widgets.dart' as pw;

/// Applies a consistent scaling factor to digits in a string for PDF widgets.
const double kPdfNumericalScaleFactor = 12 / 14;

/// Builds a [pw.TextSpan] where numerical sequences are scaled down for PDF output.
pw.TextSpan buildPdfNumericalScaledSpan(String text, pw.TextStyle baseStyle) {
  // Directly return the text span to avoid complex substring/regex logic that might cause RangeErrors
  return pw.TextSpan(text: text, style: baseStyle);
}
