/// Maps Western digits to Eastern Arabic numerals (٠–٩) per design system §2.3.
String toEasternArabicDigits(String input) {
  const western = '0123456789';
  const eastern = '٠١٢٣٤٥٦٧٨٩';
  final buffer = StringBuffer();
  for (final codeUnit in input.runes) {
    final ch = String.fromCharCode(codeUnit);
    final i = western.indexOf(ch);
    buffer.write(i >= 0 ? eastern[i] : ch);
  }
  return buffer.toString();
}
