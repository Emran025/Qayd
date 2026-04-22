import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qayd/application/vouchers/dtos/get_tripartite_detail_output.dart';
import 'package:qayd/application/vouchers/dtos/tripartite_transfer_summary_dto.dart';
import 'package:qayd/core/utils/money_formatter.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/value_objects/agreement_status.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_badge.dart';
import 'package:qayd/presentation/components/atomic/qayd_money_display.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/navigation/qayd_page_route.dart';
import 'package:qayd/presentation/pages/vouchers/tripartite_detail_cubit.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_detail_page.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/utils/voucher_image_export.dart';
import 'package:qayd/presentation/utils/voucher_pdf_export.dart';
import 'package:qayd/presentation/utils/voucher_sharing_util.dart';

/// Dedicated detail page for tripartite (intermediary) transfers.
///
/// Shows both legs (A→C receipt and C→B payment) as a unified transfer view.
/// The mediator can view the full flow and share/export the receipt that
/// is presented as being between the two external parties (A and B).
class TripartiteDetailPage extends StatelessWidget {
  const TripartiteDetailPage({super.key});

  /// Navigate to this page from a [TripartiteTransferSummaryDto].
  static Future<void> show(
    BuildContext context,
    TripartiteTransferSummaryDto transfer,
  ) {
    return Navigator.of(context).push<void>(
      QaydPageRoute.slideFromStart<void>(
        builder: (ctx) => BlocProvider(
          create: (_) => TripartiteDetailCubit(
            InjectionContainer.getVoucherDetailsUseCase,
          )..load(
              receiptVoucherId: transfer.receiptVoucher?.id,
              paymentVoucherId: transfer.paymentVoucher?.id,
              transferGroupId: transfer.transferGroupId,
              sourceName: transfer.sourceName,
              destinationName: transfer.destinationName,
              mediatorName: transfer.affectedName,
              amountMinorUnits: transfer.amountMinorUnits,
              currencyCode: transfer.currencyCode,
              currencySymbol: transfer.currencySymbol,
              currencyDigits: transfer.currencyDigits,
              currencyNameAr: transfer.currencyNameAr,
              dateIso: transfer.dateIso,
            ),
          child: const TripartiteDetailPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripartiteDetailCubit, TripartiteDetailState>(
      builder: (context, state) {
        return Scaffold(
          appBar: QaydAppBar(
            title: 'تفاصيل التحويل الوسيط',
            actions: [
              if (state is TripartiteDetailReady) _ShareMenu(data: state.data),
            ],
          ),
          body: switch (state) {
            TripartiteDetailInitial() ||
            TripartiteDetailLoading() =>
              const Center(child: CircularProgressIndicator()),
            TripartiteDetailFailure(:final failure) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(SpacingTokens.lg),
                  child: QaydText(
                    failure.messageAr,
                    slot: QaydTextStyleSlot.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            TripartiteDetailReady(:final data) =>
              _TripartiteDetailBody(data: data),
          },
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Share Menu ───────────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _ShareMenu extends StatelessWidget {
  const _ShareMenu({required this.data});

  final GetTripartiteDetailOutput data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Use the receipt voucher for sharing (it's the "sender" facing document).
    // Falls back to payment voucher if receipt is not available.
    final shareData = data.receiptVoucher ?? data.paymentVoucher;
    if (shareData == null) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      tooltip: 'خيارات المشاركة',
      color: scheme.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      onSelected: (val) {
        switch (val) {
          case 'share_text':
            shareTripartiteAsText(context, data);
            break;
          case 'share_image':
            shareVoucherAsFormattedImage(context, shareData,
                forceTripartiteLayout: true);
            break;
          case 'share_pdf':
            shareVoucherAsPdf(context, shareData, forceTripartiteLayout: true);
            break;
          case 'view_receipt':
            if (data.receiptVoucher != null) {
              VoucherDetailPage.show(context, data.receiptVoucher!.id);
            }
            break;
          case 'view_payment':
            if (data.paymentVoucher != null) {
              VoucherDetailPage.show(context, data.paymentVoucher!.id);
            }
            break;
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'share_text',
          child: ListTile(
            leading: const Icon(Icons.text_snippet_outlined),
            title: Text(AppStringsAr.shareAsTextTooltip),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'share_image',
          child: ListTile(
            leading: const Icon(Icons.image_outlined),
            title: Text(AppStringsAr.shareAsImageTooltip),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'share_pdf',
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: Text(AppStringsAr.exportSharePdfTooltip),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        if (data.receiptVoucher != null && !data.isTrueTripartite)
          PopupMenuItem(
            value: 'view_receipt',
            child: ListTile(
              leading: const Icon(Icons.south_west_rounded),
              title: const Text('عرض سند القبض'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (data.paymentVoucher != null && !data.isTrueTripartite)
          PopupMenuItem(
            value: 'view_payment',
            child: ListTile(
              leading: const Icon(Icons.north_east_rounded),
              title: const Text('عرض سند الصرف'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Detail Body ──────────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _TripartiteDetailBody extends StatelessWidget {
  const _TripartiteDetailBody({required this.data});

  final GetTripartiteDetailOutput data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;
    final dateStr = DateFormat.yMMMd('en').format(DateTime.parse(data.dateIso));
    final createdStr = DateFormat('hh:mm a  dd/MM/yyyy', 'en')
        .format(DateTime.parse(data.createdAtIso));

    return ListView(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      children: [
        // ── Transfer Type Header ───────────────────────────────────────
        Row(
          children: [
            Icon(Icons.swap_horiz_rounded, color: gold, size: 28),
            const SizedBox(width: SpacingTokens.sm),
            QaydText(
              'تحويل وسيط',
              slot: QaydTextStyleSlot.headlineSmall,
            ),
            const SizedBox(width: SpacingTokens.sm),
            if (data.isFullyAccepted)
              QaydBadge.agreement(
                status: AgreementStatus.accepted,
                context: context,
              )
            else
              QaydBadge.agreement(
                status: AgreementStatus.underRequest,
                context: context,
              ),
          ],
        ),
        const SizedBox(height: SpacingTokens.sm),

        // ── Agreement badges for external parties ────────────────────
        Wrap(
          spacing: SpacingTokens.xs,
          runSpacing: SpacingTokens.xs,
          children: [
            QaydBadge.agreement(
              status: AgreementStatus.values.byName(data.senderStatusCode),
              context: context,
              label: 'المرسل',
            ),
            QaydBadge.agreement(
              status: AgreementStatus.values.byName(data.receiverStatusCode),
              context: context,
              label: 'المستلم',
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.md),

        // ── Amount card ──────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [scheme.surface, scheme.surfaceContainerLow],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: gold.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.04),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                right: -25,
                top: -25,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: gold.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(SpacingTokens.lg),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        QaydText(
                          'مبلغ التحويل',
                          slot: QaydTextStyleSlot.labelLarge,
                          color: scheme.onSurfaceVariant,
                        ),
                        Icon(
                          Icons.swap_horiz_rounded,
                          color: gold,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: SpacingTokens.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        QaydMoneyDisplay(
                          money: Money.nonNegative(
                            data.amountMinorUnits,
                            CurrencyCode(
                              code: data.currencyCode,
                              nameAr: data.currencyNameAr,
                              symbol: data.currencySymbol,
                              fractionalDigits: data.currencyDigits,
                            ),
                          ),
                          size: QaydMoneyDisplaySize.large,
                          fontWeight: FontWeight.w800,
                        ),
                        const SizedBox(width: SpacingTokens.xs),
                        QaydText(
                          data.currencySymbol,
                          slot: QaydTextStyleSlot.titleLarge,
                          color: gold,
                        ),
                      ],
                    ),
                    if (data.feeAmountMinorUnits != null &&
                        data.feeAmountMinorUnits! > 0) ...[
                      const SizedBox(height: SpacingTokens.sm),
                      Row(
                        children: [
                          Icon(Icons.receipt_long_rounded,
                              size: 14, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          QaydText(
                            'رسوم التحويل: ${MoneyFormatter.formatWithSymbol(
                              data.feeAmountMinorUnits! / 100,
                              data.currencySymbol,
                              fractionalDigits: data.currencyDigits,
                            )}',
                            slot: QaydTextStyleSlot.bodySmall,
                            color: scheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: SpacingTokens.xl),

        // ── Flow Diagram ─────────────────────────────────────────────
        _TripartiteFlowCard(data: data),
        const SizedBox(height: SpacingTokens.md),

        // ── Core details ─────────────────────────────────────────────
        _DetailRow(label: 'التاريخ', value: dateStr),
        _DetailRow(label: 'المرسل', value: data.sourceName),
        _DetailRow(label: 'الوسيط', value: data.mediatorName),
        _DetailRow(label: 'المستلم', value: data.destinationName),

        if (data.description != null && data.description!.isNotEmpty)
          _DetailRow(label: 'البيان', value: data.description!),

        // ── Timestamps ───────────────────────────────────────────────
        const SizedBox(height: SpacingTokens.sm),
        _DetailRow(label: 'تاريخ الإنشاء', value: createdStr),

        // ── Leg cards (clickable links to individual vouchers) ────────
        if (!data.isTrueTripartite) ...[
          const SizedBox(height: SpacingTokens.md),
          _LegLinksSection(data: data),
        ],

        // ── Transfer Group ID ────────────────────────────────────────
        const SizedBox(height: SpacingTokens.md),
        Container(
          padding: const EdgeInsets.all(SpacingTokens.sm),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.fingerprint_rounded,
                  size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: QaydText(
                  'معرف المجموعة: ${data.transferGroupId.substring(0, 8)}…',
                  slot: QaydTextStyleSlot.labelSmall,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // ── Preview section (uses receipt voucher data) ──────────────
        if (data.receiptVoucher != null) ...[
          const SizedBox(height: SpacingTokens.md),
          _TripartitePreviewSection(data: data),
        ],

        const SizedBox(height: SpacingTokens.xxl),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Flow Card ────────────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _TripartiteFlowCard extends StatelessWidget {
  const _TripartiteFlowCard({required this.data});

  final GetTripartiteDetailOutput data;

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: gold.withValues(alpha: 0.05),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: gold.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.account_tree_outlined, size: 18, color: gold),
                const SizedBox(width: SpacingTokens.sm),
                QaydText(
                  AppStringsAr.tripartiteFlowTitle,
                  slot: QaydTextStyleSlot.labelLarge,
                  color: gold,
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.md),
            Row(
              children: [
                Expanded(
                  child: _FlowNode(
                    label: AppStringsAr.tripartiteFlowSource,
                    name: data.sourceName,
                    isActive: true,
                  ),
                ),
                Icon(Icons.arrow_forward_rounded,
                    size: 16, color: scheme.onSurfaceVariant),
                Expanded(
                  child: _FlowNode(
                    label: AppStringsAr.tripartiteFlowMediator,
                    name: data.isTrueTripartite
                        ? (InjectionContainer.sharedPreferences
                                .getString('company_name') ??
                            'حسابي (وسيط)')
                        : data.mediatorName,
                    isActive: true,
                    isGold: true,
                  ),
                ),
                Icon(Icons.arrow_forward_rounded,
                    size: 16, color: scheme.onSurfaceVariant),
                Expanded(
                  child: _FlowNode(
                    label: AppStringsAr.tripartiteFlowDestination,
                    name: data.destinationName,
                    isActive: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FlowNode extends StatelessWidget {
  const _FlowNode({
    required this.label,
    required this.name,
    required this.isActive,
    this.isGold = false,
  });

  final String label;
  final String name;
  final bool isActive;
  final bool isGold;

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        QaydText(
          label,
          slot: QaydTextStyleSlot.labelSmall,
          color: isActive
              ? (isGold ? gold : scheme.primary)
              : scheme.onSurfaceVariant,
        ),
        const SizedBox(height: SpacingTokens.xs),
        QaydText(
          name,
          slot: QaydTextStyleSlot.bodySmall,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          color: isActive ? scheme.onSurface : scheme.onSurfaceVariant,
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Leg Links Section ────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _LegLinksSection extends StatelessWidget {
  const _LegLinksSection({required this.data});

  final GetTripartiteDetailOutput data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long_rounded, size: 18, color: gold),
                const SizedBox(width: SpacingTokens.sm),
                QaydText(
                  'السندات المرتبطة',
                  slot: QaydTextStyleSlot.labelLarge,
                  color: gold,
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.md),

            // Receipt leg
            if (data.receiptVoucher != null)
              _LegCard(
                icon: Icons.south_west_rounded,
                label: 'سند القبض',
                subtitle: '${data.sourceName} ← ${data.mediatorName}',
                statusCode: data.receiptVoucher!.receiverStatusCode,
                stateCode: data.receiptVoucher!.stateCode,
                onTap: () => VoucherDetailPage.show(
                  context,
                  data.receiptVoucher!.id,
                ),
              ),

            if (data.receiptVoucher != null && data.paymentVoucher != null)
              const SizedBox(height: SpacingTokens.sm),

            // Payment leg
            if (data.paymentVoucher != null)
              _LegCard(
                icon: Icons.north_east_rounded,
                label: 'سند الصرف',
                subtitle: '${data.mediatorName} → ${data.destinationName}',
                statusCode: data.paymentVoucher!.receiverStatusCode,
                stateCode: data.paymentVoucher!.stateCode,
                onTap: () => VoucherDetailPage.show(
                  context,
                  data.paymentVoucher!.id,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegCard extends StatelessWidget {
  const _LegCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.statusCode,
    required this.stateCode,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final String statusCode;
  final String stateCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.sm),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: scheme.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: gold),
            ),
            const SizedBox(width: SpacingTokens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  QaydText(
                    label,
                    slot: QaydTextStyleSlot.labelMedium,
                  ),
                  const SizedBox(height: 2),
                  QaydText(
                    subtitle,
                    slot: QaydTextStyleSlot.bodySmall,
                    color: scheme.onSurfaceVariant,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: SpacingTokens.sm),
            QaydBadge.agreement(
              status: AgreementStatus.values.byName(statusCode),
              context: context,
            ),
            const SizedBox(width: SpacingTokens.xs),
            Icon(Icons.chevron_left_rounded,
                size: 20, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Preview Section ──────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _TripartitePreviewSection extends StatelessWidget {
  const _TripartitePreviewSection({required this.data});

  final GetTripartiteDetailOutput data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.md,
              vertical: SpacingTokens.sm,
            ),
            decoration: BoxDecoration(
              color: gold.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.preview_rounded, size: 18, color: gold),
                const SizedBox(width: SpacingTokens.sm),
                QaydText(
                  'معاينة الإيصال',
                  slot: QaydTextStyleSlot.labelLarge,
                  color: gold,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(SpacingTokens.md),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: VoucherImageCard(data: data.receiptVoucher!),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Detail Row Widget ────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: QaydText(
              label,
              slot: QaydTextStyleSlot.bodyMedium,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            flex: 3,
            child: QaydText(
              value,
              slot: QaydTextStyleSlot.labelMedium,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
