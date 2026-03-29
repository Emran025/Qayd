import 'package:flutter/material.dart';
import 'package:qayd/core/utils/money_formatter.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/presentation/theme/type_scale.dart';
import 'package:qayd/presentation/utils/eastern_arabic_digits.dart';

/// Visual weight for monetary amounts (maps to design system moneyLarge / Medium / Small).
enum QaydMoneyDisplaySize {
  large,
  medium,
  small,
}

/// Formatted currency-style amount with optional Eastern Arabic numerals (default on).
class QaydMoneyDisplay extends StatelessWidget {
  const QaydMoneyDisplay({
    super.key,
    required this.money,
    this.displayNegative = false,
    this.size = QaydMoneyDisplaySize.medium,
    this.useEasternArabicNumerals = true,
    this.locale = 'ar',
    this.textAlign = TextAlign.start,
    this.semanticsLabel,
  });

  final Money money;
  final bool displayNegative;
  final QaydMoneyDisplaySize size;
  final bool useEasternArabicNumerals;
  final String locale;
  final TextAlign textAlign;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textScaler = MediaQuery.textScalerOf(context);
    num divisor = 1;
    for (var i = 0; i < money.fractionalDigits; i++) {
      divisor *= 10;
    }
    final major = money.minorUnits / divisor;
    var formatted = MoneyFormatter.formatDecimal(
      major,
      locale: locale,
      minimumFractionDigits: money.fractionalDigits,
      maximumFractionDigits: money.fractionalDigits,
    );
    if (useEasternArabicNumerals) {
      formatted = toEasternArabicDigits(formatted);
    }

    final textStyle = switch (size) {
      QaydMoneyDisplaySize.large => TypeScale.moneyLarge(scheme),
      QaydMoneyDisplaySize.medium => TypeScale.moneyMedium(scheme),
      QaydMoneyDisplaySize.small => TypeScale.moneySmall(scheme),
    };

    final displayText = displayNegative ? '($formatted)' : formatted;
    final color = displayNegative ? scheme.error : null;
    final style = color != null ? textStyle.copyWith(color: color) : textStyle;

    return Text(
      displayText,
      style: style,
      textScaler: textScaler,
      textAlign: textAlign,
      semanticsLabel: semanticsLabel,
    );
  }
}
