import 'package:flutter/material.dart';
import 'package:qayd/presentation/utils/numerical_styling.dart';

/// Typography aligned with [TextTheme] / type scale; respects RTL via [TextAlign.start].
enum QaydTextStyleSlot {
  displayLarge,
  displayMedium,
  displaySmall,
  headlineLarge,
  headlineMedium,
  headlineSmall,
  titleLarge,
  titleMedium,
  titleSmall,
  bodyLarge,
  bodyMedium,
  bodySmall,
  labelLarge,
  labelMedium,
  labelSmall,
}

class QaydText extends StatelessWidget {
  const QaydText(
    this.data, {
    super.key,
    this.slot = QaydTextStyleSlot.bodyLarge,
    this.style,
    this.color,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
    this.semanticsLabel,
  });

  final String data;
  final QaydTextStyleSlot slot;
  final TextStyle? style;
  final Color? color;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool softWrap;
  final String? semanticsLabel;

  TextStyle? _resolvedStyle(TextTheme theme) {
    final base = switch (slot) {
      QaydTextStyleSlot.displayLarge => theme.displayLarge,
      QaydTextStyleSlot.displayMedium => theme.displayMedium,
      QaydTextStyleSlot.displaySmall => theme.displaySmall,
      QaydTextStyleSlot.headlineLarge => theme.headlineLarge,
      QaydTextStyleSlot.headlineMedium => theme.headlineMedium,
      QaydTextStyleSlot.headlineSmall => theme.headlineSmall,
      QaydTextStyleSlot.titleLarge => theme.titleLarge,
      QaydTextStyleSlot.titleMedium => theme.titleMedium,
      QaydTextStyleSlot.titleSmall => theme.titleSmall,
      QaydTextStyleSlot.bodyLarge => theme.bodyLarge,
      QaydTextStyleSlot.bodyMedium => theme.bodyMedium,
      QaydTextStyleSlot.bodySmall => theme.bodySmall,
      QaydTextStyleSlot.labelLarge => theme.labelLarge,
      QaydTextStyleSlot.labelMedium => theme.labelMedium,
      QaydTextStyleSlot.labelSmall => theme.labelSmall,
    };
    if (style != null) {
      return base?.merge(style) ?? style;
    }
    if (color != null) {
      return base?.copyWith(color: color) ?? base;
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _resolvedStyle(Theme.of(context).textTheme);
    if (resolved == null) return Text(data, textAlign: textAlign);

    return Text.rich(
      buildNumericalScaledSpan(data, resolved),
      textScaler: MediaQuery.textScalerOf(context),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      semanticsLabel: semanticsLabel,
    );
  }
}
