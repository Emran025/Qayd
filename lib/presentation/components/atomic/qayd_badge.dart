import 'package:flutter/material.dart';
import 'package:qayd/domain/value_objects/agreement_status.dart';
import 'package:qayd/domain/value_objects/voucher_state.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

/// Unified status badge for Voucher states (Draft/Confirmed) and Agreement statuses (Accepted/Rejected/etc).
class QaydBadge extends StatelessWidget {
  const QaydBadge._({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.fgColor,
    this.isDashed = false,
  });

  final String label;
  final IconData icon;
  final Color bgColor;
  final Color fgColor;
  final bool isDashed;

  factory QaydBadge(
      {required VoucherState state, required BuildContext context}) {
    final custom = Theme.of(context).extension<QaydCustomColors>()!;
    final (bg, fg, dashed) = switch (state) {
      VoucherState.draft => (custom.draftState, custom.badgeOnDraft, true),
      VoucherState.confirmed => (
          custom.confirmedState,
          custom.badgeOnConfirmed,
          false
        ),
      VoucherState.settled => (
          custom.settledState,
          custom.badgeOnSettled,
          false
        ),
      VoucherState.withdrawn => (
          ColorTokens.errorSoft.withValues(alpha: 0.2),
          ColorTokens.errorDeep,
          false
        ),
    };
    final label = _stateLabel(state);
    final icon = _stateIcon(state);
    return QaydBadge._(
        label: label, icon: icon, bgColor: bg, fgColor: fg, isDashed: dashed);
  }

  factory QaydBadge.agreement({
    required AgreementStatus status,
    required BuildContext context,
    String? label,
  }) {
    final custom = Theme.of(context).extension<QaydCustomColors>()!;
    final (bg, fg, dashed) = switch (status) {
      AgreementStatus.underRequest => (
          custom.draftState.withValues(alpha: 0.1),
          custom.draftState,
          true
        ),
      AgreementStatus.accepted => (
          custom.confirmedState.withValues(alpha: 0.1),
          custom.confirmedState,
          false
        ),
      AgreementStatus.rejected => (
          ColorTokens.errorSoft.withValues(alpha: 0.2),
          ColorTokens.errorDeep,
          false
        ),
      AgreementStatus.unverified => (
          custom.draftState.withValues(alpha: 0.1),
          custom.badgeOnDraft,
          true
        ),
    };
    final statusLabel = _agreementLabel(status);
    final icon = _agreementIcon(status);
    final finalLabel = label != null ? '$label: $statusLabel' : statusLabel;
    return QaydBadge._(
        label: finalLabel,
        icon: icon,
        bgColor: bg,
        fgColor: fg,
        isDashed: dashed);
  }

  static String _stateLabel(VoucherState state) {
    return switch (state) {
      VoucherState.draft => AppStrings.voucherStateDraft,
      VoucherState.confirmed => AppStrings.voucherStateConfirmed,
      VoucherState.settled => AppStrings.voucherStateSettled,
      VoucherState.withdrawn => AppStrings.voucherStateWithdrawn,
    };
  }

  static String _agreementLabel(AgreementStatus status) {
    return switch (status) {
      AgreementStatus.underRequest => AppStrings.agreementUnderRequest,
      AgreementStatus.accepted => AppStrings.agreementAccepted,
      AgreementStatus.rejected => AppStrings.agreementRejected,
      AgreementStatus.unverified => AppStrings.agreementUnverified,
    };
  }

  static IconData _stateIcon(VoucherState state) {
    return switch (state) {
      VoucherState.draft => Icons.edit_note_rounded,
      VoucherState.confirmed => Icons.check_circle_outline_rounded,
      VoucherState.settled => Icons.verified_rounded,
      VoucherState.withdrawn => Icons.u_turn_right_rounded,
    };
  }

  static IconData _agreementIcon(AgreementStatus status) {
    return switch (status) {
      AgreementStatus.underRequest => Icons.pending_outlined,
      AgreementStatus.accepted => Icons.assignment_turned_in_rounded,
      AgreementStatus.rejected => Icons.unpublished_outlined,
      AgreementStatus.unverified => Icons.help_outline_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(
      icon,
      size: 14,
      color: fgColor,
    );

    final padding = Padding(
      padding: const EdgeInsets.all(SpacingTokens.xs),
      child: iconWidget,
    );

    final badge = DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(RadiusTokens.xs),
        border: Border.all(color: fgColor.withValues(alpha: 0.15), width: 1),
      ),
      child: isDashed
          ? CustomPaint(
              painter: _DashedRoundedRectPainter(
                color: fgColor.withValues(alpha: 0.4),
                radius: RadiusTokens.xs,
              ),
              child: padding,
            )
          : padding,
    );

    return Tooltip(
      message: label,
      preferBelow: false,
      child: badge,
    );
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  _DashedRoundedRectPainter({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final r =
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(r);
    const dash = 3.0;
    const gap = 2.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final end = (d + dash).clamp(0.0, metric.length);
        canvas.drawPath(
            metric.extractPath(d, end),
            Paint()
              ..color = color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.0);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter oldDelegate) =>
      oldDelegate.color != color;
}
