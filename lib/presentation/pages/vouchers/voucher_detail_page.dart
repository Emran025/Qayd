import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_output.dart';
import 'package:qayd/core/utils/money_formatter.dart';
import 'package:qayd/domain/value_objects/agreement_status.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_badge.dart';
import 'package:qayd/presentation/components/atomic/qayd_money_display.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/navigation/qayd_page_route.dart';
import 'package:qayd/presentation/pages/messaging/notification_preview_mode.dart';
import 'package:qayd/presentation/pages/messaging/notification_preview_page.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_detail_cubit.dart';
import 'package:qayd/presentation/utils/voucher_pdf_export.dart';
import 'package:qayd/presentation/utils/voucher_sharing_util.dart';
import 'package:qayd/presentation/utils/voucher_image_export.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/utils/voucher_state_codec.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/presentation/widgets/voucher_qr_dialog.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_create_page.dart';
import '../../../di/injection_container.dart';

class VoucherDetailPage extends StatefulWidget {
  const VoucherDetailPage({super.key});

  /// Centralized navigation entry point to ensure Clean Architecture parity.
  /// Decouples the UI from Cubit instantiation/injection logic.
  static Future<void> show(BuildContext context, String voucherId) {
    return Navigator.of(context).push<void>(
      QaydPageRoute.slideFromStart<void>(
        builder: (ctx) => BlocProvider(
          create: (_) => VoucherDetailCubit(
            InjectionContainer.getVoucherDetailsUseCase,
            InjectionContainer.confirmVoucherUseCase,
            InjectionContainer.withdrawVoucherUseCase,
          )..load(voucherId),
          child: const VoucherDetailPage(),
        ),
      ),
    );
  }

  @override
  State<VoucherDetailPage> createState() => _VoucherDetailPageState();
}

class _VoucherDetailPageState extends State<VoucherDetailPage> {
  final GlobalKey _boundaryKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VoucherDetailCubit, VoucherDetailState>(
      listenWhen: (prev, cur) {
        if (cur is VoucherDetailReady && cur.confirmErrorAr != null) {
          return true;
        }
        if (cur is VoucherDetailReady && cur.showPostConfirmMessage) {
          return true;
        }
        return false;
      },
      listener: (context, state) {
        if (state is VoucherDetailReady && state.confirmErrorAr != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.confirmErrorAr!)),
          );
          context.read<VoucherDetailCubit>().clearConfirmError();
        }
        if (state is VoucherDetailReady && state.showPostConfirmMessage) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStringsAr.voucherConfirmedSuccess),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<VoucherDetailCubit>().clearPostConfirmMessage();
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: QaydAppBar(
            title: state is VoucherDetailReady
                ? AppStringsAr.voucherDetailTitle
                : AppStringsAr.voucherDetailTitle,
          
            actions: [
              if (state is VoucherDetailReady) ...[
                IconButton(
                  tooltip: AppStringsAr.voucherSendMessageTooltip,
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  onPressed: () {
                    Navigator.of(context).push<void>(
                      QaydPageRoute.slideFromStart<void>(
                        builder: (ctx) => NotificationPreviewPage(
                          mode: NotificationPreviewVoucher(state.data.id),
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  tooltip: AppStringsAr.shareAsTextTooltip,
                  icon: const Icon(Icons.text_snippet_outlined),
                  onPressed: () => shareVoucherAsText(context, state.data),
                ),
                IconButton(
                  tooltip: AppStringsAr.shareAsImageTooltip,
                  icon: const Icon(Icons.image_outlined),
                  onPressed: () => shareVoucherAsFormattedImage(context, state.data),
                ),
                IconButton(
                  tooltip: AppStringsAr.exportSharePdfTooltip,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  onPressed: () => shareVoucherAsPdf(context, state.data),
                ),
                if (state.data.qrData != null)
                  IconButton(
                    tooltip: AppStringsAr.qrCodeShowTooltip,
                    icon: const Icon(Icons.qr_code_2_rounded),
                    onPressed: () {
                      final amount = MoneyFormatter.formatWithSymbol(
                        state.data.amountMinorUnits /
                            (state.data.currencyDigits == 0
                                ? 1
                                : (state.data.currencyDigits == 2
                                    ? 100
                                    : 100)), // Simplification for detail view
                        state.data.currencySymbol,
                        fractionalDigits: state.data.currencyDigits,
                      );

                      showDialog<void>(
                        context: context,
                        builder: (ctx) => VoucherQrDialog(
                          qrData: state.data.qrData!,
                          voucherDescription: state.data.description ?? '',
                          amountLabel: amount,
                        ),
                      );
                    },
                  ),
                
                // --- Protocol §2: Withdrawal Action ---
                if (state.data.stateCode == 'draft' || 
                    state.data.receiverStatusCode == 'under_request' ||
                    state.data.receiverStatusCode == 'rejected')
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'withdraw') {
                        context.read<VoucherDetailCubit>().withdraw();
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'withdraw',
                        child: Text('سحب السند'),
                      ),
                    ],
                  ),
              ],
            ],
          ),
          body: switch (state) {
            VoucherDetailInitial() || VoucherDetailLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            VoucherDetailFailure(:final failure) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(SpacingTokens.lg),
                  child: QaydText(
                    failure.messageAr,
                    slot: QaydTextStyleSlot.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            VoucherDetailReady(:final data, :final confirming) => Stack(
                children: [
                  _VoucherDetailBody(data: data, boundaryKey: _boundaryKey),
                  if (confirming)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Color(0x33000000),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              ),
          },
          bottomNavigationBar: state is VoucherDetailReady &&
                  state.data.canApprove &&
                  state.data.stateCode == 'draft'
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(SpacingTokens.md),
                    child: FilledButton(
                      onPressed: state.confirming
                          ? null
                          : () => context.read<VoucherDetailCubit>().confirm(),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: SpacingTokens.md,
                        ),
                        backgroundColor:
                            Theme.of(context).extension<QaydCustomColors>()!.goldAccent,
                        foregroundColor: ColorTokens.navy950,
                      ),
                      child: Text(AppStringsAr.voucherConfirmAction),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _VoucherDetailBody extends StatelessWidget {
  const _VoucherDetailBody({required this.data, required this.boundaryKey});

  final GetVoucherDetailsOutput data;
  final GlobalKey boundaryKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;
    final isReceipt = data.typeCode == 'receipt';
    final dateStr = DateFormat.yMMMd('ar').format(DateTime.parse(data.dateIso));
    final createdStr = DateFormat('hh:mm a  dd/MM/yyyy', 'ar')
        .format(DateTime.parse(data.createdAtIso));

    return RepaintBoundary(
      key: boundaryKey,
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: ListView(
          padding: const EdgeInsets.all(SpacingTokens.lg),
          children: [
            // ── Withdrawn banner ──────────────────────────────────────────
            if (data.stateCode == 'withdrawn')
              Padding(
                padding: const EdgeInsets.only(bottom: SpacingTokens.md),
                child: Container(
                  padding: const EdgeInsets.all(SpacingTokens.md),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: QaydText(
                              'تم سحب هذا السند. هل تريد تصحيح الوجهة وإعادة الإرسال؟',
                              slot: QaydTextStyleSlot.bodySmall,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: SpacingTokens.sm),
                      FilledButton.icon(
                        onPressed: () {
                           Navigator.of(context).push(
                             QaydPageRoute.slideFromStart(
                               builder: (ctx) => VoucherCreatePage(
                                 initialQrData: {
                                   'type': data.typeCode == 'payment' ? VoucherType.payment : VoucherType.receipt,
                                   'date': DateTime.parse(data.dateIso),
                                   'amountMinorUnits': data.amountMinorUnits,
                                   'description': data.description,
                                   'counterpartyAccountId': data.counterpartyAccountId,
                                   'originVoucherId': data.id,
                                 },
                               ),
                             ),
                           );
                        },
                        icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                        label: const Text('تصحيح وإعادة توجيه'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Successor link ───────────────────────────────────────────
            if (data.successorVoucherId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: SpacingTokens.md),
                child: InkWell(
                  onTap: () => VoucherDetailPage.show(context, data.successorVoucherId!),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(SpacingTokens.sm),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.forward_rounded, size: 16, color: Colors.amber),
                        const SizedBox(width: SpacingTokens.sm),
                        Expanded(
                          child: QaydText(
                            AppStringsAr.voucherJumpHeader,
                            slot: QaydTextStyleSlot.labelMedium,
                            color: Colors.amber,
                          ),
                        ),
                        const Icon(Icons.chevron_left_rounded, size: 16, color: Colors.amber),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Origin document link (enhanced with prominent button) ────
            if (data.originVoucherId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: SpacingTokens.md),
                child: Card(
                  color: scheme.primary.withValues(alpha: 0.08),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: scheme.primary.withValues(alpha: 0.25)),
                  ),
                  child: InkWell(
                    onTap: () => VoucherDetailPage.show(context, data.originVoucherId!),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(SpacingTokens.md),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.reply_rounded, size: 22, color: scheme.primary),
                          ),
                          const SizedBox(width: SpacingTokens.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStringsAr.voucherOriginDocumentButton,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: scheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppStringsAr.voucherReplyHeader,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: scheme.primary.withValues(alpha: 0.7),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_left_rounded, size: 24, color: scheme.primary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ── Type, Status & Badge row ─────────────────────────────────
            Row(
              children: [
                Icon(
                  isReceipt ? Icons.south_west_rounded : Icons.north_east_rounded,
                  color: gold,
                  size: 28,
                ),
                const SizedBox(width: SpacingTokens.sm),
                QaydText(
                  isReceipt
                      ? AppStringsAr.voucherTypeReceipt
                      : AppStringsAr.voucherTypePayment,
                  slot: QaydTextStyleSlot.headlineSmall,
                ),
                const SizedBox(width: SpacingTokens.sm),
                QaydBadge(state: voucherStateFromCode(data.stateCode), context: context),
                if (data.isContingent) ...[
                  const SizedBox(width: SpacingTokens.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      AppStringsAr.tripartiteContingentBadge,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: SpacingTokens.sm),

            // ── Agreement badges row ─────────────────────────────────────
            Wrap(
              spacing: SpacingTokens.xs,
              runSpacing: SpacingTokens.xs,
              children: [
                QaydBadge.agreement(
                  status: AgreementStatus.values.byName(data.senderStatusCode),
                  context: context,
                  label: AppStringsAr.voucherSenderLabel,
                ),
                QaydBadge.agreement(
                  status: AgreementStatus.values.byName(data.receiverStatusCode),
                  context: context,
                  label: AppStringsAr.voucherReceiverLabel,
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.md),

            // ── Amount card ──────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(SpacingTokens.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    QaydText(
                      AppStringsAr.voucherAmountLabel,
                      slot: QaydTextStyleSlot.labelMedium,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: SpacingTokens.xs),
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
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: SpacingTokens.md),

            // ── Core details rows ────────────────────────────────────────
            _Row(
              label: AppStringsAr.voucherDateLabel,
              value: dateStr,
            ),
            _Row(
              label: AppStringsAr.affectedAccountSection,
              value: data.affectedName,
            ),
            _Row(
              label: AppStringsAr.counterpartySection,
              value: data.counterpartyName,
            ),

            // ── Tripartite flow diagram ──────────────────────────────────
            if (data.isTripartite) ...[
              const SizedBox(height: SpacingTokens.sm),
              _TripartiteFlowDiagram(data: data),
              const SizedBox(height: SpacingTokens.sm),
            ],

            if (data.referenceNumber != null && data.referenceNumber!.isNotEmpty)
              _Row(
                label: AppStringsAr.voucherReferenceLabel,
                value: data.referenceNumber!,
              ),
            if (data.description != null && data.description!.isNotEmpty)
              _Row(
                label: AppStringsAr.voucherDescriptionLabel,
                value: data.description!,
              ),
            if (data.notes != null && data.notes!.isNotEmpty)
              _Row(
                label: AppStringsAr.voucherNotesLabel,
                value: data.notes!,
              ),

            // ── Timestamps section ───────────────────────────────────────
            const SizedBox(height: SpacingTokens.sm),
            _Row(
              label: AppStringsAr.voucherCreatedAtLabel,
              value: createdStr,
            ),
            if (data.confirmedAtIso != null)
              _Row(
                label: AppStringsAr.voucherConfirmedAtLabel,
                value: DateFormat('hh:mm a  dd/MM/yyyy', 'ar')
                    .format(DateTime.parse(data.confirmedAtIso!)),
              ),
            if (data.settledAtIso != null)
              _Row(
                label: AppStringsAr.voucherSettledAtLabel,
                value: DateFormat('hh:mm a  dd/MM/yyyy', 'ar')
                    .format(DateTime.parse(data.settledAtIso!)),
              ),

            // ── Voucher Image Preview (same format as exported image) ────
            const SizedBox(height: SpacingTokens.md),
            _VoucherPreviewSection(data: data),

            // ── Cost / Profit Centers ────────────────────────────────────
            if (data.costCenters.isNotEmpty) ...[
              const SizedBox(height: SpacingTokens.md),
              _CostCenterSection(costCenters: data.costCenters),
            ],

            // ── Attachments section (detailed) ──────────────────────────
            if (data.attachmentCount > 0) ...[
              const SizedBox(height: SpacingTokens.md),
              _AttachmentsSection(
                attachments: data.attachments,
                attachmentCount: data.attachmentCount,
              ),
            ],

            // ── Collateral section (enhanced with settlements) ──────────
            if (data.hasCollateral) ...[
              const SizedBox(height: SpacingTokens.md),
              _CollateralSummaryCard(data: data),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Voucher Preview Section (rendered inline like the exported image) ─────
// ══════════════════════════════════════════════════════════════════════════════

class _VoucherPreviewSection extends StatelessWidget {
  const _VoucherPreviewSection({required this.data});

  final GetVoucherDetailsOutput data;

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
                  AppStringsAr.voucherPreviewCardTitle,
                  slot: QaydTextStyleSlot.labelLarge,
                  color: gold,
                ),
              ],
            ),
          ),
          // The actual image card embedded inline
          Padding(
            padding: const EdgeInsets.all(SpacingTokens.md),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: VoucherImageCard(data: data),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Cost / Profit Center Section ─────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _CostCenterSection extends StatelessWidget {
  const _CostCenterSection({required this.costCenters});

  final List<CostCenterSummary> costCenters;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;

    return Card(
      color: gold.withValues(alpha: 0.06),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: gold.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart_outline_rounded, size: 20, color: gold),
                const SizedBox(width: SpacingTokens.sm),
                Expanded(
                  child: Text(
                    AppStringsAr.voucherCostCentersSection,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.sm),
            Wrap(
              spacing: SpacingTokens.sm,
              runSpacing: SpacingTokens.sm,
              children: costCenters.map((cc) {
                final isCost = cc.typeCode == 'cost';
                final typeLabel = isCost
                    ? AppStringsAr.voucherCostCenterTypeCost
                    : AppStringsAr.voucherCostCenterTypeProfit;
                final chipColor = isCost
                    ? Colors.red.shade300
                    : Colors.green.shade400;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: chipColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: chipColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCost ? Icons.trending_down_rounded : Icons.trending_up_rounded,
                        size: 14,
                        color: chipColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${cc.name} ($typeLabel)',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: chipColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Attachments Section ──────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _AttachmentsSection extends StatelessWidget {
  const _AttachmentsSection({
    required this.attachments,
    required this.attachmentCount,
  });

  final List<VoucherAttachmentSummary> attachments;
  final int attachmentCount;

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _iconForMime(String mime) {
    if (mime.startsWith('image/')) return Icons.image_outlined;
    if (mime.startsWith('video/')) return Icons.videocam_outlined;
    if (mime.contains('pdf')) return Icons.picture_as_pdf_outlined;
    return Icons.insert_drive_file_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;

    return Card(
      color: gold.withValues(alpha: 0.06),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: gold.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_file_rounded, size: 20, color: gold),
                const SizedBox(width: SpacingTokens.sm),
                Expanded(
                  child: Text(
                    AppStringsAr.voucherAttachmentsSection,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    AppStringsAr.voucherAttachmentCountLabel(attachmentCount),
                    style: TextStyle(
                      color: gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (attachments.isNotEmpty) ...[
              const SizedBox(height: SpacingTokens.sm),
              ...attachments.map((att) => Padding(
                    padding: const EdgeInsets.only(bottom: SpacingTokens.xs),
                    child: Container(
                      padding: const EdgeInsets.all(SpacingTokens.sm),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: gold.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _iconForMime(att.mimeType),
                              size: 18,
                              color: gold,
                            ),
                          ),
                          const SizedBox(width: SpacingTokens.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  att.fileName,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: scheme.onSurface,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatFileSize(att.byteSize),
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Data Row ────────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

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
              slot: QaydTextStyleSlot.bodyLarge,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Collateral Summary Card (enhanced with settlement links) ─────────────
// ══════════════════════════════════════════════════════════════════════════════

class _CollateralSummaryCard extends StatelessWidget {
  const _CollateralSummaryCard({required this.data});

  final GetVoucherDetailsOutput data;

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;
    final scheme = Theme.of(context).colorScheme;

    final (statusColor, statusLabel) = switch (data.collateralStatusCode) {
      'active' => (Colors.green.shade400, 'نشط'),
      'expired' => (Colors.orange.shade400, 'منتهي'),
      'liquidated' => (Colors.red.shade400, 'تمت التصفية'),
      'released' => (Colors.blue.shade400, 'محرر'),
      _ => (Colors.grey, data.collateralStatusCode ?? '—'),
    };

    final valueStr = data.collateralValueMinor != null
        ? NumberFormat.decimalPattern('ar')
            .format(data.collateralValueMinor! / 100)
        : '—';

    return Card(
      color: gold.withValues(alpha: 0.06),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: gold.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield_rounded, size: 20, color: gold),
                const SizedBox(width: SpacingTokens.sm),
                Expanded(
                  child: Text(
                    AppStringsAr.voucherCollateralSection,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.sm),
            if (data.collateralDescription != null &&
                data.collateralDescription!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: SpacingTokens.xs),
                child: Text(
                  data.collateralDescription!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Value and expiry
            Row(
              children: [
                Icon(Icons.attach_money_rounded,
                    size: 14, color: scheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '$valueStr ${data.currencyCode}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                if (data.collateralExpiryIso != null) ...[
                  const SizedBox(width: SpacingTokens.lg),
                  Icon(Icons.event_rounded,
                      size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat.yMMMd('ar')
                        .format(DateTime.parse(data.collateralExpiryIso!)),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),

            // ── Settlement voucher links ─────────────────────────────────
            if (data.collateralSettlementVoucherIds.isNotEmpty) ...[
              const SizedBox(height: SpacingTokens.md),
              const Divider(height: 1),
              const SizedBox(height: SpacingTokens.sm),
              Text(
                AppStringsAr.voucherCollateralSettlementsTitle,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
              ),
              const SizedBox(height: SpacingTokens.xs),
              ...data.collateralSettlementVoucherIds.asMap().entries.map(
                    (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: SpacingTokens.xs),
                  child: InkWell(
                    onTap: () => VoucherDetailPage.show(context, entry.value),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.sm,
                        vertical: SpacingTokens.xs,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.receipt_long_rounded,
                              size: 16, color: scheme.primary),
                          const SizedBox(width: SpacingTokens.sm),
                          Expanded(
                            child: Text(
                              AppStringsAr.voucherCollateralSettlementLink(entry.key + 1),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          Icon(Icons.chevron_left_rounded,
                              size: 16, color: scheme.primary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Tripartite Flow Diagram ─────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _TripartiteFlowDiagram extends StatelessWidget {
  const _TripartiteFlowDiagram({required this.data});

  final GetVoucherDetailsOutput data;

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;
    final scheme = Theme.of(context).colorScheme;

    // Determine roles based on whether we are looking at the receipt (A->C) or payment (C->B) leg
    final isReceipt = data.tripartiteRole == 'intermediary_receipt';
    final sourceName = isReceipt ? data.counterpartyName : data.linkedPartyName ?? '—';
    final destName = isReceipt ? data.linkedPartyName ?? '—' : data.counterpartyName;

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
                    name: sourceName,
                    isActive: isReceipt,
                  ),
                ),
                Icon(Icons.arrow_forward_rounded,
                    size: 16, color: scheme.onSurfaceVariant),
                Expanded(
                  child: _FlowNode(
                    label: AppStringsAr.tripartiteFlowMediator,
                    name: data.affectedName,
                    isActive: true,
                    isGold: true,
                  ),
                ),
                Icon(Icons.arrow_forward_rounded,
                    size: 16, color: scheme.onSurfaceVariant),
                Expanded(
                  child: _FlowNode(
                    label: AppStringsAr.tripartiteFlowDestination,
                    name: destName,
                    isActive: !isReceipt,
                  ),
                ),
              ],
            ),
            if (data.isContingent) ...[
              const SizedBox(height: SpacingTokens.md),
              Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: scheme.error),
                  const SizedBox(width: SpacingTokens.xs),
                  Expanded(
                    child: QaydText(
                      AppStringsAr.tripartiteContingentHint,
                      slot: QaydTextStyleSlot.bodySmall,
                      color: scheme.error,
                    ),
                  ),
                ],
              ),
            ],
            if (data.transferGroupId != null) ...[
              const SizedBox(height: SpacingTokens.md),
              const Divider(height: 1),
              const SizedBox(height: SpacingTokens.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: QaydText(
                      AppStringsAr.tripartiteGroupLabel,
                      slot: QaydTextStyleSlot.bodySmall,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: QaydText(
                      data.transferGroupId!.substring(0, 8), // Short preview
                      slot: QaydTextStyleSlot.labelSmall,
                      textAlign: TextAlign.end,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
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
          color: isActive ? (isGold ? gold : scheme.primary) : scheme.onSurfaceVariant,
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
