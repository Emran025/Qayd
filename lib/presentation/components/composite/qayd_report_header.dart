import 'package:flutter/material.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/utils/qayd_header_config.dart';

enum QaydReportHeaderType {
  voucher,
  statement,
}

/// A professional, reusable report header replicating the PDF branding.
///
/// Includes:
/// - A stylized top bar with custom colors and branding (Arabic/English).
/// - A central logo badge.
/// - A title row with optional bordered boxes for voucher numbers and dates.
class QaydReportHeader extends StatelessWidget {
  final QaydReportHeaderType? type;
  final String? title;
  final String? subtitle;
  final String? englishTitle;
  final String? englishSubtitle;

  // Optional side boxes for vouchers/reports
  final String? labelRight;
  final String? valueRight;
  final String? labelLeft;
  final String? valueLeft;

  // Mediator info or extra subtitle for tripartite
  final String? extraSubtitle;

  const QaydReportHeader({
    super.key,
    this.type,
    this.title,
    this.subtitle,
    this.englishTitle,
    this.englishSubtitle,
    this.labelRight,
    this.valueRight,
    this.labelLeft,
    this.valueLeft,
    this.extraSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    final prefs = InjectionContainer.sharedPreferences;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // The 'Header Bar' (blue bar) should always show the general branding
    // unless explicitly overridden by brandingTitle/brandingSubtitle.
    final config = QaydHeaderConfig.resolve(
      prefs,
      isStatement: type == QaydReportHeaderType.statement,
    );

    final resolvedBrandingTitle =
        title != null && (type == null) ? title! : config.title;
    final resolvedBrandingSubtitle = subtitle ?? config.subtitle;
    final resolvedEngTitle = englishTitle ?? config.englishTitle;
    final resolvedEngSubtitle = englishSubtitle ?? config.englishSubtitle;

    // The 'Document Title' is shown in the center of the white area
    final resolvedDocumentTitle = title ??
        (type == QaydReportHeaderType.voucher
            ? AppStrings.financialBond
            : AppStrings.accountStatement);

    // PDF-style colors
    final headerBg = isDark ? ColorTokens.navy800 : const Color(0xFFE8EDF3);
    final navy = isDark ? Colors.white : ColorTokens.navy900;
    final muted = isDark ? ColorTokens.slate400 : ColorTokens.slate600;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header Bar ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: headerBg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Row(
            children: [
              // Right: Arabic info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resolvedBrandingTitle,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: navy,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      resolvedBrandingSubtitle,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 8,
                        color: muted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Center: Logo badge
              const _LogoBadge(),

              // Left: English info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      resolvedEngTitle,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 9,
                        color: navy,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.end,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      resolvedEngSubtitle,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 7,
                        color: muted,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Title Row with Side Boxes ────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (valueRight != null)
                    _BorderedBox(
                      label: labelRight ?? AppStrings.bondNumber1,
                      value: valueRight!,
                    )
                  else
                    const Spacer(),
                  if (valueLeft != null)
                    _BorderedBox(
                      label: labelLeft ?? AppStrings.theDate1,
                      value: valueLeft!,
                    )
                  else
                    const Spacer(),
                ],
              ),

              const SizedBox(height: 8),

              // Main Title in Center
              Center(
                child: Text(
                  resolvedDocumentTitle,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: navy,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              if (extraSubtitle != null) ...[
                const SizedBox(height: 1),
                Text(
                  extraSubtitle!,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 8.5,
                    color: muted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: 40,
          height: 40,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.account_balance_rounded,
            color: ColorTokens.goldAccent,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _BorderedBox extends StatelessWidget {
  final String label;
  final String value;

  const _BorderedBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navy = isDark ? Colors.white : ColorTokens.navy900;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: navy, width: 1.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 9,
              color: navy,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 10,
              color: navy,
            ),
          ),
        ],
      ),
    );
  }
}
