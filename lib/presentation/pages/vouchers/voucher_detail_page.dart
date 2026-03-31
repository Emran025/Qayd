import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_output.dart';
import 'package:qayd/core/utils/money_formatter.dart';
import 'package:qayd/domain/value_objects/money.dart';
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
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/utils/voucher_state_codec.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/presentation/widgets/voucher_qr_dialog.dart';

class VoucherDetailPage extends StatefulWidget {
  const VoucherDetailPage({super.key});

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
          appBar: AppBar(
            title: QaydText(
              state is VoucherDetailReady
                  ? AppStringsAr.voucherDetailTitle
                  : AppStringsAr.voucherDetailTitle,
              slot: QaydTextStyleSlot.titleLarge,
            ),
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
                  onPressed: () => shareVoucherAsText(state.data),
                ),
                IconButton(
                  tooltip: AppStringsAr.shareAsImageTooltip,
                  icon: const Icon(Icons.image_outlined),
                  onPressed: () => shareVoucherAsImage(context, _boundaryKey),
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

    return RepaintBoundary(
      key: boundaryKey,
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: ListView(
          padding: const EdgeInsets.all(SpacingTokens.lg),
          children: [
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
            QaydBadge(state: voucherStateFromCode(data.stateCode)),
          ],
        ),
        const SizedBox(height: SpacingTokens.md),
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
          ],
        ),
      ),
    );
  }
}

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
