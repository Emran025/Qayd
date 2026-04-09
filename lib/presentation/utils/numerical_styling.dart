import 'package:flutter/material.dart';

/// Applies a consistent scaling factor to digits in a string to make them 
/// visually match the Arabic text size (which often appears smaller than 
/// Western digits in certain fonts like Cairo).
/// 
/// As per user request: if base size is 14, digits should be 12.
/// Ratio = 12 / 14 = ~0.857
const double kNumericalScaleFactor = 12 / 14;

/// Builds a [TextSpan] where numerical sequences are scaled down.
TextSpan buildNumericalScaledSpan(String text, TextStyle baseStyle) {
  final digitRegex = RegExp(r'[0-9,\.]+');
  final matches = digitRegex.allMatches(text);
  
  if (matches.isEmpty) {
    return TextSpan(text: text, style: baseStyle);
  }

  final spans = <TextSpan>[];
  int lastMatchEnd = 0;
  
  final scaledStyle = baseStyle.copyWith(
    fontSize: baseStyle.fontSize != null 
        ? baseStyle.fontSize! * kNumericalScaleFactor 
        : null,
  );

  for (final match in matches) {
    final start = match.start;
    final end = match.end;

    if (start > lastMatchEnd) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd, start),
      ));
    }

    spans.add(TextSpan(
      text: text.substring(start, end),
      style: scaledStyle,
    ));

    lastMatchEnd = end;
  }

  if (lastMatchEnd < text.length) {
    spans.add(TextSpan(
      text: text.substring(lastMatchEnd),
    ));
  }

  return TextSpan(children: spans, style: baseStyle);
}
