import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_output.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/utils/money_formatter.dart';
import 'package:qayd/domain/value_objects/agreement_status.dart';
import 'package:qayd/domain/value_objects/collateral_id.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/core/utils/currency_util.dart';
import 'package:qayd/presentation/components/atomic/qayd_dialog.dart';
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
import 'package:qayd/presentation/pages/vouchers/voucher_create_cubit.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_suggestions_cubit.dart';
import 'package:qayd/presentation/widgets/attachment_gallery_dialog.dart';
import 'package:qayd/presentation/widgets/collateral_detail_dialog.dart';
import 'package:qayd/presentation/widgets/liquidation_wizard_sheet.dart';
import 'package:qayd/domain/entities/collateral.dart';
import 'package:qayd/domain/entities/collateral_revaluation.dart';
import 'package:qayd/domain/repositories/attachment_repository.dart';
import 'package:qayd/data/services/attachment_storage_service.dart';
import 'package:qayd/presentation/utils/attachment_file_opener.dart';
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
            attachmentRepository: InjectionContainer.attachmentRepository,
            attachmentStorage: InjectionContainer.attachmentStorage,
            collateralRepository: InjectionContainer.collateralRepository,
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
    final scheme = Theme.of(context).colorScheme;
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
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  tooltip: 'المزيد',
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
                        shareVoucherAsText(context, state.data);
                        break;
                      case 'share_image':
                        shareVoucherAsFormattedImage(context, state.data,
                            forceNormalLayout: false);
                        break;
                      case 'share_pdf':
                        shareVoucherAsPdf(context, state.data,
                            forceNormalLayout: false);
                        break;
                      case 'qr_code':
                        final amountStr = MoneyFormatter.formatWithSymbol(
                          state.data.amountMinorUnits /
                              (state.data.currencyDigits == 0
                                  ? 1
                                  : (state.data.currencyDigits == 2
                                      ? 100
                                      : 100)),
                          state.data.currencySymbol,
                          fractionalDigits: state.data.currencyDigits,
                        );
                        showDialog<void>(
                          context: context,
                          builder: (ctx) => VoucherQrDialog(
                            qrData: state.data.qrData!,
                            voucherDescription: state.data.description ?? '',
                            amountLabel: amountStr,
                          ),
                        );
                        break;
                      case 'withdraw':
                        _withdrawVoucher(context, state.data);
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
                    if (state.data.qrData != null)
                      PopupMenuItem(
                        value: 'qr_code',
                        child: ListTile(
                          leading: const Icon(Icons.qr_code_2_rounded),
                          title: Text(AppStringsAr.qrCodeShowTooltip),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    if (state.data.isCreator &&
                        state.data.stateCode != 'settled' &&
                        state.data.stateCode != 'withdrawn' &&
                        state.data.receiverStatusCode != 'accepted')
                      PopupMenuItem(
                        value: 'withdraw',
                        child: ListTile(
                          leading: const Icon(Icons.undo_rounded,
                              color: ColorTokens.errorDeep),
                          title: Text(AppStringsAr.statementChatWithdraw,
                              style: const TextStyle(
                                  color: ColorTokens.errorDeep)),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
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
                        backgroundColor: Theme.of(context)
                            .extension<QaydCustomColors>()!
                            .goldAccent,
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

  Future<void> _withdrawVoucher(
    BuildContext context,
    GetVoucherDetailsOutput data,
  ) async {
    final cubit = context.read<VoucherDetailCubit>();

    final action = await QaydDialog.show<String>(
      context: context,
      icon: Icons.warning_amber_rounded,
      iconColor: Theme.of(context).colorScheme.error,
      title: AppStringsAr.voucherWithdrawConfirmTitle,
      content: AppStringsAr.voucherWithdrawConfirmBody,
      primaryActionLabel: AppStringsAr.voucherRedirectToOthers,
      onPrimaryAction: () => Navigator.pop(context, 'edit_others'),
      secondaryActionLabel: AppStringsAr.voucherDeleteOrWithdraw,
      onSecondaryAction: () => Navigator.pop(context, 'withdraw'),
      tertiaryActionLabel: AppStringsAr.templateEditCancel,
      onTertiaryAction: () => Navigator.pop(context, 'cancel'),
    );

    if (action == 'withdraw') {
      await cubit.withdraw();
    } else if (action == 'edit_others') {
      if (!context.mounted) return;
      Navigator.of(context)
          .push(
            QaydPageRoute.slideFromStart(
              builder: (ctx) => MultiBlocProvider(
                providers: [
                  BlocProvider<VoucherCreateCubit>(
                    create: (_) => VoucherCreateCubit(
                      InjectionContainer.createVoucherUseCase,
                      InjectionContainer.createTripartiteTransferUseCase,
                    ),
                  ),
                  BlocProvider<VoucherSuggestionsCubit>(
                    create: (_) => VoucherSuggestionsCubit(
                      InjectionContainer.getAutoSuggestionsUseCase,
                      InjectionContainer
                          .markNotificationMessageProcessedUseCase,
                    ),
                  ),
                ],
                child: VoucherCreatePage(
                  initialQrData: {
                    'type': data.typeCode == 'payment'
                        ? VoucherType.payment
                        : VoucherType.receipt,
                    'date': DateTime.parse(data.dateIso),
                    'amountMinorUnits': data.amountMinorUnits,
                    'description': data.description,
                    'counterpartyAccountId': data.counterpartyAccountId,
                    'currencyCode': data.currencyCode,
                    'editingVoucherId': data.id,
                  },
                ),
              ),
            ),
          )
          .then((_) => cubit.load(data.id));
    }
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
    final dateStr = DateFormat.yMMMd('en').format(DateTime.parse(data.dateIso));
    final createdStr = DateFormat('hh:mm a  dd/MM/yyyy', 'en')
        .format(DateTime.parse(data.createdAtIso));

    return RepaintBoundary(
      key: boundaryKey,
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: ListView(
          padding: const EdgeInsets.all(SpacingTokens.lg),
          children: [
            // ── Dual Transfer banner ──────────────────────────────────────
            if (data.transferGroupId != null && !data.isTripartite)
              Padding(
                padding: const EdgeInsets.only(bottom: SpacingTokens.md),
                child: Container(
                  padding: const EdgeInsets.all(SpacingTokens.md),
                  decoration: BoxDecoration(
                    color: gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: gold.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.swap_calls_rounded, color: gold, size: 20),
                      const SizedBox(width: SpacingTokens.sm),
                      Expanded(
                        child: QaydText(
                          data.typeCode == 'receipt'
                              ? 'هذا السند جزء من عملية تحويل مزدوج. الطرف المستلم النهائي هو: ${data.linkedPartyName ?? 'غير محدد'}'
                              : 'هذا السند جزء من عملية تحويل مزدوج. الطرف المرسل الأصلي هو: ${data.linkedPartyName ?? 'غير محدد'}',
                          slot: QaydTextStyleSlot.bodySmall,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Withdrawn banner ──────────────────────────────────────────
            if (data.stateCode == 'withdrawn')
              Padding(
                padding: const EdgeInsets.only(bottom: SpacingTokens.md),
                child: Container(
                  padding: const EdgeInsets.all(SpacingTokens.md),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: Colors.orange, size: 20),
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
                              builder: (ctx) => MultiBlocProvider(
                                providers: [
                                  BlocProvider<VoucherCreateCubit>(
                                    create: (_) => VoucherCreateCubit(
                                      InjectionContainer.createVoucherUseCase,
                                      InjectionContainer
                                          .createTripartiteTransferUseCase,
                                    ),
                                  ),
                                  BlocProvider<VoucherSuggestionsCubit>(
                                    create: (_) => VoucherSuggestionsCubit(
                                      InjectionContainer
                                          .getAutoSuggestionsUseCase,
                                      InjectionContainer
                                          .markNotificationMessageProcessedUseCase,
                                    ),
                                  ),
                                ],
                                child: VoucherCreatePage(
                                  initialQrData: {
                                    'type': data.typeCode == 'payment'
                                        ? VoucherType.payment
                                        : VoucherType.receipt,
                                    'date': DateTime.parse(data.dateIso),
                                    'amountMinorUnits': data.amountMinorUnits,
                                    'description': data.description,
                                    'counterpartyAccountId':
                                        data.counterpartyAccountId,
                                    'currencyCode': data.currencyCode,
                                    'editingVoucherId': data.id,
                                  },
                                ),
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
                  onTap: () =>
                      VoucherDetailPage.show(context, data.successorVoucherId!),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(SpacingTokens.sm),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.forward_rounded,
                            size: 16, color: Colors.amber),
                        const SizedBox(width: SpacingTokens.sm),
                        Expanded(
                          child: QaydText(
                            AppStringsAr.voucherJumpHeader,
                            slot: QaydTextStyleSlot.labelMedium,
                            color: Colors.amber,
                          ),
                        ),
                        const Icon(Icons.chevron_left_rounded,
                            size: 16, color: Colors.amber),
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
                    side: BorderSide(
                        color: scheme.primary.withValues(alpha: 0.25)),
                  ),
                  child: InkWell(
                    onTap: () =>
                        VoucherDetailPage.show(context, data.originVoucherId!),
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
                            child: Icon(Icons.reply_rounded,
                                size: 22, color: scheme.primary),
                          ),
                          const SizedBox(width: SpacingTokens.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStringsAr.voucherOriginDocumentButton,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: scheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppStringsAr.voucherReplyHeader,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: scheme.primary
                                            .withValues(alpha: 0.7),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_left_rounded,
                              size: 24, color: scheme.primary),
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
                  isReceipt
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
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
                QaydBadge(
                    state: voucherStateFromCode(data.stateCode),
                    context: context),
                if (data.isContingent) ...[
                  const SizedBox(width: SpacingTokens.sm),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                  status:
                      AgreementStatus.values.byName(data.receiverStatusCode),
                  context: context,
                  label: AppStringsAr.voucherReceiverLabel,
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.md),

            // ── Amount card (Light Premium Redesign) ─────────────────────
            Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.surface,
                    scheme.surfaceContainerLow,
                  ],
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
                              AppStringsAr.voucherAmountLabel,
                              slot: QaydTextStyleSlot.labelLarge,
                              color: scheme.onSurfaceVariant,
                            ),
                            Icon(
                              Icons.account_balance_wallet_rounded,
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
                              CurrencyUtil.getArabicName(data.currencyCode),
                              slot: QaydTextStyleSlot.titleSmall,
                              color: gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: SpacingTokens.xl),

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
            if (data.transferGroupId != null) ...[
              const SizedBox(height: SpacingTokens.sm),
              _TripartiteFlowDiagram(data: data),
              const SizedBox(height: SpacingTokens.sm),
            ],

            if (data.referenceNumber != null &&
                data.referenceNumber!.isNotEmpty)
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
              label: AppStringsAr.createdAtLabel,
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
              BlocBuilder<VoucherDetailCubit, VoucherDetailState>(
                builder: (context, cubitState) {
                  final ready =
                      cubitState is VoucherDetailReady ? cubitState : null;
                  return _AttachmentsSection(
                    attachments: data.attachments,
                    attachmentCount: data.attachmentCount,
                    voucherId: data.id,
                    decryptedImages: ready?.decryptedAttachments ?? const [],
                    imageNames: ready?.attachmentNames ?? const [],
                    loadingImages: ready?.loadingAttachments ?? false,
                    attachmentRepository:
                        InjectionContainer.attachmentRepository,
                    attachmentStorage: InjectionContainer.attachmentStorage,
                    onTapView: () {
                      final cubit = context.read<VoucherDetailCubit>();
                      cubit.loadAttachmentImages();
                    },
                  );
                },
              ),
            ],

            // ── Collateral section (enhanced with settlements) ──────────
            if (data.hasCollateral) ...[
              const SizedBox(height: SpacingTokens.md),
              BlocListener<VoucherDetailCubit, VoucherDetailState>(
                listenWhen: (prev, cur) {
                  // Fire when pendingCollateralDialog flips to true and entity is loaded
                  if (cur is VoucherDetailReady &&
                      cur.pendingCollateralDialog &&
                      cur.collateralEntity != null) {
                    return true;
                  }
                  return false;
                },
                listener: (context, state) {
                  final s = state as VoucherDetailReady;
                  // Clear the flag first so it doesn't re-fire
                  context
                      .read<VoucherDetailCubit>()
                      .clearPendingCollateralDialog();
                  // Open the dialog
                  CollateralDetailDialog.show(
                    context,
                    collateral: s.collateralEntity!,
                    revaluations: s.collateralRevaluations,
                    decryptedImages: s.collateralImages,
                    imageNames: s.collateralImageNames,
                  );
                },
                child: BlocBuilder<VoucherDetailCubit, VoucherDetailState>(
                  builder: (context, cubitState) {
                    final ready =
                        cubitState is VoucherDetailReady ? cubitState : null;
                    return _CollateralSummaryCard(
                      data: data,
                      collateralEntity: ready?.collateralEntity,
                      revaluations: ready?.collateralRevaluations ?? const [],
                      collateralImages: ready?.collateralImages ?? const [],
                      collateralImageNames:
                          ready?.collateralImageNames ?? const [],
                      loadingCollateral: ready?.loadingCollateral ?? false,
                      onTapViewDetails: () {
                        context
                            .read<VoucherDetailCubit>()
                            .loadCollateralDetails(
                                openDialogWhenReady: true);
                      },
                    );
                  },
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
              child: VoucherImageCard(data: data, forceNormalLayout: true),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: costCenters.map((cc) {
                final isCost = cc.typeCode == 'cost';
                final typeLabel = isCost
                    ? AppStringsAr.voucherCostCenterTypeCost
                    : AppStringsAr.voucherCostCenterTypeProfit;
                final chipColor =
                    isCost ? Colors.red.shade300 : Colors.green.shade400;

                return Padding(
                  padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main Center Chip
                      InkWell(
                        onTap: cc.dimensions.isNotEmpty
                            ? () => _showDimensionsSheet(context, cc)
                            : null,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: chipColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: chipColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCost
                                    ? Icons.trending_down_rounded
                                    : Icons.trending_up_rounded,
                                size: 14,
                                color: chipColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${cc.name} ($typeLabel)',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: chipColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              if (cc.dimensions.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '+${cc.dimensions.length}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: chipColor.withValues(alpha: 0.7),
                                        fontSize: 10,
                                      ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.info_outline_rounded,
                                    size: 14, color: chipColor),
                              ],
                            ],
                          ),
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

  void _showDimensionsSheet(BuildContext context, CostCenterSummary cc) {
    final scheme = Theme.of(context).colorScheme;
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.only(bottom: SpacingTokens.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle and Header
            const SizedBox(height: SpacingTokens.sm),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: SpacingTokens.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
              child: Row(
                children: [
                  Icon(Icons.layers_outlined, color: gold, size: 22),
                  const SizedBox(width: SpacingTokens.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        QaydText(
                          cc.name,
                          slot: QaydTextStyleSlot.titleMedium,
                        ),
                        QaydText(
                          AppStringsAr.voucherCostCentersSection,
                          slot: QaydTextStyleSlot.labelSmall,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: SpacingTokens.xl),

            // Dimension list
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding:
                    const EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
                itemCount: cc.dimensions.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: SpacingTokens.md),
                itemBuilder: (context, index) {
                  final dim = cc.dimensions[index];
                  return Container(
                    padding: const EdgeInsets.all(SpacingTokens.md),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: gold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.label_important_outline_rounded,
                              color: gold, size: 20),
                        ),
                        const SizedBox(width: SpacingTokens.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              QaydText(
                                dim.categoryName,
                                slot: QaydTextStyleSlot.labelSmall,
                                color: scheme.onSurfaceVariant,
                              ),
                              QaydText(
                                dim.name,
                                slot: QaydTextStyleSlot.bodyLarge,
                                // weight: FontWeight.w600,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
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
    required this.voucherId,
    this.decryptedImages = const [],
    this.imageNames = const [],
    this.loadingImages = false,
    this.onTapView,
    this.attachmentRepository,
    this.attachmentStorage,
  });

  final List<VoucherAttachmentSummary> attachments;
  final int attachmentCount;
  final String voucherId;
  final List<Uint8List> decryptedImages;
  final List<String> imageNames;
  final bool loadingImages;
  final VoidCallback? onTapView;
  final AttachmentRepository? attachmentRepository;
  final AttachmentStorageService? attachmentStorage;

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
    final hasImages = attachments.any((a) => a.mimeType.startsWith('image/'));

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

            // ── Decrypted Image Thumbnails ────────────────────────────────
            if (decryptedImages.isNotEmpty) ...[
              const SizedBox(height: SpacingTokens.md),
              SizedBox(
                height: 88,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: decryptedImages.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: SpacingTokens.sm),
                  itemBuilder: (context, i) {
                    return GestureDetector(
                      onTap: () => AttachmentGalleryDialog.show(
                        context,
                        imageBytes: decryptedImages,
                        fileNames: imageNames,
                        initialIndex: i,
                      ),
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: gold.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.shadow.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(
                              decryptedImages[i],
                              fit: BoxFit.cover,
                            ),
                            // Subtle overlay gradient
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 24,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.4),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Zoom icon overlay
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.zoom_in_rounded,
                                  size: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            // ── View Images Button (when not yet loaded) ──────────────────
            if (hasImages && decryptedImages.isEmpty) ...[
              const SizedBox(height: SpacingTokens.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: loadingImages ? null : onTapView,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: gold.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(
                      vertical: SpacingTokens.sm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: loadingImages
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: gold,
                          ),
                        )
                      : Icon(Icons.photo_library_rounded,
                          size: 18, color: gold),
                  label: Text(
                    loadingImages
                        ? 'جاري فك تشفير الصور...'
                        : 'استعراض الصور المرفقة',
                    style: TextStyle(color: gold, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],

            // ── File list ─────────────────────────────────────────────────
            if (attachments.isNotEmpty) ...[
              const SizedBox(height: SpacingTokens.sm),
              ...attachments.asMap().entries.map((entry) {
                final att = entry.value;
                final isImage = att.mimeType.startsWith('image/');
                final isPdf = att.mimeType.contains('pdf');
                final isVideo = att.mimeType.startsWith('video/');

                // Find decrypted image index (already in memory)
                final imageIdx = isImage && decryptedImages.isNotEmpty
                    ? imageNames.indexOf(att.fileName)
                    : -1;

                // ── Tile content (shared between image and file tiles) ──
                final tileContent = Container(
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
                      // Thumbnail for loaded images, icon otherwise
                      if (isImage && imageIdx >= 0)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.memory(
                            decryptedImages[imageIdx],
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
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
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurface,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  _formatFileSize(att.byteSize),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: gold.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isPdf
                                        ? 'PDF'
                                        : isVideo
                                            ? 'فيديو'
                                            : isImage
                                                ? 'صورة'
                                                : 'ملف',
                                    style: TextStyle(
                                      color: gold,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Action icon
                      Icon(
                        isImage && imageIdx >= 0
                            ? Icons.zoom_in_rounded
                            : Icons.open_in_new_rounded,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: SpacingTokens.xs),
                  child: isImage
                      // ── Image: open in gallery ───────────────────────
                      ? InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: imageIdx >= 0
                              ? () => AttachmentGalleryDialog.show(
                                    context,
                                    imageBytes: decryptedImages,
                                    fileNames: imageNames,
                                    initialIndex: imageIdx,
                                  )
                              : onTapView, // load+decrypt first
                          child: tileContent,
                        )
                      // ── Non-image: decrypt → OS open ─────────────────
                      : attachmentRepository != null &&
                              attachmentStorage != null
                          ? AttachmentFileTile(
                              summary: att,
                              attachmentRepository: attachmentRepository!,
                              attachmentStorage: attachmentStorage!,
                              voucherId: voucherId,
                              child: tileContent,
                            )
                          : tileContent,
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Collateral Summary Card (Enhanced) ──────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _CollateralSummaryCard extends StatelessWidget {
  const _CollateralSummaryCard({
    required this.data,
    this.collateralEntity,
    this.revaluations = const [],
    this.collateralImages = const [],
    this.collateralImageNames = const [],
    this.loadingCollateral = false,
    this.onTapViewDetails,
  });

  final GetVoucherDetailsOutput data;
  final Collateral? collateralEntity;
  final List<CollateralRevaluation> revaluations;
  final List<Uint8List> collateralImages;
  final List<String> collateralImageNames;
  final bool loadingCollateral;
  final VoidCallback? onTapViewDetails;

  Color _statusColor(String? statusCode) {
    return switch (statusCode) {
      'active' => const Color(0xFF4CAF50),
      'expired' => const Color(0xFFFF9800),
      'liquidated' => const Color(0xFF9E9E9E),
      'released' => const Color(0xFF2196F3),
      _ => const Color(0xFF9E9E9E),
    };
  }

  String _statusLabel(String? statusCode) {
    return switch (statusCode) {
      'active' => 'نشط',
      'expired' => 'منتهي الصلاحية',
      'liquidated' => 'تمت التصفية',
      'released' => 'تم الإفراج',
      _ => 'غير محدد',
    };
  }

  IconData _statusIcon(String? statusCode) {
    return switch (statusCode) {
      'active' => Icons.shield_rounded,
      'expired' => Icons.warning_amber_rounded,
      'liquidated' => Icons.gavel_rounded,
      'released' => Icons.lock_open_rounded,
      _ => Icons.shield_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;
    final statusColor = _statusColor(data.collateralStatusCode);
    final canLiquidate = collateralEntity?.canLiquidate ?? false;
    final isActiveOrExpired = data.collateralStatusCode == 'active' ||
        data.collateralStatusCode == 'expired';

    return Card(
      color: statusColor.withValues(alpha: 0.05),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: statusColor.withValues(alpha: 0.25), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Row ──────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _statusIcon(data.collateralStatusCode),
                    size: 20,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: SpacingTokens.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStringsAr.voucherCollateralSection,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 2),
                      if (data.collateralDescription != null)
                        Text(
                          data.collateralDescription!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _statusLabel(data.collateralStatusCode),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: SpacingTokens.md),
            Divider(
                color: scheme.outlineVariant.withValues(alpha: 0.3), height: 1),
            const SizedBox(height: SpacingTokens.md),

            // ── Value & Expiry Info ─────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _CollateralInfoTile(
                    label: AppStringsAr.voucherCollateralValueLabel,
                    value: data.collateralValueMinor != null
                        ? MoneyFormatter.formatWithSymbol(
                            data.collateralValueMinor! / 100,
                            CurrencyUtil.getArabicName(data.currencyCode),
                          )
                        : '—',
                    icon: Icons.monetization_on_outlined,
                    color: gold,
                  ),
                ),
                const SizedBox(width: SpacingTokens.md),
                Expanded(
                  child: _CollateralInfoTile(
                    label: AppStringsAr.voucherCollateralExpiryLabel,
                    value: data.collateralExpiryIso != null
                        ? DateFormat.yMMMd('ar')
                            .format(DateTime.parse(data.collateralExpiryIso!))
                        : 'غير محدد',
                    icon: Icons.event_outlined,
                    color: data.collateralStatusCode == 'expired'
                        ? const Color(0xFFFF9800)
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            // ── Collateral Image Thumbnails ─────────────────────────────
            if (collateralImages.isNotEmpty) ...[
              const SizedBox(height: SpacingTokens.md),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: collateralImages.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: SpacingTokens.sm),
                  itemBuilder: (context, i) {
                    return GestureDetector(
                      onTap: () => AttachmentGalleryDialog.show(
                        context,
                        imageBytes: collateralImages,
                        fileNames: collateralImageNames,
                        initialIndex: i,
                      ),
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: gold.withValues(alpha: 0.25),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(
                              collateralImages[i],
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Icon(
                                  Icons.zoom_in_rounded,
                                  size: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else if (loadingCollateral) ...[
              const SizedBox(height: SpacingTokens.md),
              const Center(child: CircularProgressIndicator.adaptive()),
            ],

            // ── Settlement Voucher Links ─────────────────────────────────
            if (data.collateralSettlementVoucherIds.isNotEmpty) ...[
              const SizedBox(height: SpacingTokens.md),
              Text(
                AppStringsAr.voucherCollateralSettlementsTitle,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: SpacingTokens.xs),
              ...data.collateralSettlementVoucherIds.asMap().entries.map((e) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => VoucherDetailPage.show(context, e.value),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SpacingTokens.sm,
                          vertical: SpacingTokens.xs,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.receipt_long_rounded,
                                size: 16, color: statusColor),
                            const SizedBox(width: SpacingTokens.xs),
                            Expanded(
                              child: Text(
                                AppStringsAr.voucherCollateralSettlementLink(
                                    e.key + 1),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_left_rounded,
                                size: 16, color: scheme.onSurfaceVariant),
                          ],
                        ),
                      ),
                    ),
                  )),
            ],

            const SizedBox(height: SpacingTokens.md),

            // ── Action Buttons ──────────────────────────────────────────
            Row(
              children: [
                // View Details button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                            // Always delegate to the cubit — it will open the
                            // dialog via BlocListener once data is ready.
                            onTapViewDetails?.call();
                          },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: gold.withValues(alpha: 0.4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: SpacingTokens.sm,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: loadingCollateral
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: gold,
                            ),
                          )
                        : Icon(Icons.info_outline_rounded,
                            size: 16, color: gold),
                    label: Text(
                      loadingCollateral ? 'جاري التحميل...' : 'عرض التفاصيل',
                      style: TextStyle(
                          color: gold,
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                    ),
                  ),
                ),

                // Liquidate / Settlement button (only for active/expired)
                if (isActiveOrExpired) ...[
                  const SizedBox(width: SpacingTokens.sm),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        final collId = data.collateralId;
                        if (collId == null) return;

                        // Compute total debt: use counterparty running balance
                        final totalDebt =
                            data.counterpartyBalances[data.currencyCode]
                                    ?.abs() ??
                                data.amountMinorUnits;

                        LiquidationWizardSheet.show(
                          context,
                          collateralDescription:
                              data.collateralDescription ?? '',
                          voucherAmountMinor: data.amountMinorUnits,
                          totalDebtMinor: totalDebt,
                          currencyCode: data.currencyCode,
                          onConfirm: (settlementType, saleValueMinor) async {
                            // Close the wizard sheet first
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }

                            // Execute the real liquidation use case
                            final result = await InjectionContainer
                                .liquidateCollateralUseCase(
                              collateralId: CollateralId(collId),
                              settlementType: settlementType,
                              saleValueMinor: saleValueMinor,
                            );

                            if (!context.mounted) return;
                            result.fold(
                              (failure) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(failure.messageAr),
                                    backgroundColor:
                                        Theme.of(context).colorScheme.error,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              },
                              (liquidated) {
                                final surplus = liquidated.surplusAmountMinor;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      surplus > 0
                                          ? 'تمت التسوية ✓  فائض: ${(surplus / 100).toStringAsFixed(2)} ${data.currencyCode}'
                                          : 'تمت تسوية الرهن بنجاح ✓',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                                // Reload to reflect updated collateral status
                                context
                                    .read<VoucherDetailCubit>()
                                    .load(data.id);
                              },
                            );
                          },
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            canLiquidate ? const Color(0xFFFF9800) : gold,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: SpacingTokens.sm,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: Icon(
                        canLiquidate
                            ? Icons.gavel_rounded
                            : Icons.handshake_rounded,
                        size: 16,
                      ),
                      label: Text(
                        canLiquidate ? 'تصفية الرهن' : 'إجراء تسوية',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper tile for displaying collateral info (value, expiry).
class _CollateralInfoTile extends StatelessWidget {
  const _CollateralInfoTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
              slot: QaydTextStyleSlot.labelMedium,
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
    final sourceName =
        isReceipt ? data.counterpartyName : data.linkedPartyName ?? '—';
    final destName =
        isReceipt ? data.linkedPartyName ?? '—' : data.counterpartyName;

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
