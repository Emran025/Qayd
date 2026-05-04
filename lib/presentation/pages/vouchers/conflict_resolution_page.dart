import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_output.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/entities/notification_message.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_money_display.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/navigation/qayd_page_route.dart';
import 'package:qayd/presentation/pages/vouchers/conflict_resolution_cubit.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


class ConflictResolutionPage extends StatelessWidget {
  const ConflictResolutionPage({super.key, required this.notification});

  final NotificationMessage notification;

  static Route<void> route(NotificationMessage notification) {
    return QaydPageRoute.slideFromStart(
      builder: (context) => BlocProvider(
        create: (_) => ConflictResolutionCubit(
          InjectionContainer.getVoucherDetailsUseCase,
          InjectionContainer.resolveConflictUseCase,
        )..load(notification),
        child: ConflictResolutionPage(notification: notification),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;

    return BlocConsumer<ConflictResolutionCubit, ConflictResolutionState>(
      listener: (context, state) {
        if (state is ConflictResolutionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.theConflictWasSuccessfully),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop();
        }
        if (state is ConflictResolutionFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.failure.messageAr)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: QaydAppBar(title: AppStrings.addressingBondConflicts),
          body: _buildBody(context, state, gold),
        );
      },
    );
  }

  Widget _buildBody(
      BuildContext context, ConflictResolutionState state, Color gold) {
    if (state is ConflictResolutionLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (state is ConflictResolutionReady) {
      return ListView(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        children: [
          QaydText(
            AppStrings.aPossibleMatchHas,
            slot: QaydTextStyleSlot.bodyMedium,
          ),
          SizedBox(height: SpacingTokens.lg),
          _ComparisonCard(
            title: AppStrings.yourLocalRecordDraft,
            icon: Icons.file_present_rounded,
            color: ColorTokens.navy800,
            voucher: state.localVoucher,
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: SpacingTokens.md),
            child: Icon(Icons.sync_alt_rounded, color: Colors.grey),
          ),
          _InboundComparisonCard(
            title: AppStrings.incomingBondSync,
            icon: Icons.cloud_sync_rounded,
            color: ColorTokens.navy950,
            payload: state.inboundPayload,
            currencyDigits: state.localVoucher.currencyDigits,
          ),
          SizedBox(height: SpacingTokens.xl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: state.isResolving
                      ? null
                      : () => context
                          .read<ConflictResolutionCubit>()
                          .resolve(merge: false),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent),
                  child: Text(AppStrings.ignoreIncomingDuplicate),
                ),
              ),
              SizedBox(width: SpacingTokens.md),
              Expanded(
                child: FilledButton(
                  onPressed: state.isResolving
                      ? null
                      : () => context
                          .read<ConflictResolutionCubit>()
                          .resolve(merge: true),
                  style: FilledButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: ColorTokens.navy950,
                  ),
                  child: state.isResolving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(AppStrings.mergeAndConfirmLocal),
                ),
              ),
            ],
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.voucher,
  });

  final String title;
  final IconData icon;
  final Color color;
  final GetVoucherDetailsOutput voucher;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.blueAccent),
              SizedBox(width: 8),
              QaydText(title, slot: QaydTextStyleSlot.labelLarge),
            ],
          ),
          SizedBox(height: SpacingTokens.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              QaydMoneyDisplay(
                money: Money.nonNegative(
                  voucher.amountMinorUnits,
                  CurrencyCode(
                    code: voucher.currencyCode,
                    nameAr: voucher.currencyNameAr,
                    symbol: voucher.currencySymbol,
                    fractionalDigits: voucher.currencyDigits,
                  ),
                ),
                size: QaydMoneyDisplaySize.large,
              ),
              QaydText(
                voucher.typeCode == 'receipt' ? AppStrings.catchStr : AppStrings.exchange,
                color: voucher.typeCode == 'receipt'
                    ? Colors.greenAccent
                    : Colors.orangeAccent,
              ),
            ],
          ),
          SizedBox(height: 8),
          QaydText(
            DateFormat.yMMMd('ar').format(DateTime.parse(voucher.dateIso)),
            slot: QaydTextStyleSlot.bodySmall,
            color: Colors.white60,
          ),
        ],
      ),
    );
  }
}

class _InboundComparisonCard extends StatelessWidget {
  const _InboundComparisonCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.payload,
    required this.currencyDigits,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Map<String, dynamic> payload;
  final int currencyDigits;

  @override
  Widget build(BuildContext context) {
    final amount = payload['amount_minor'] as int? ?? 0;
    final currency = payload['currency_code'] as String? ?? '';
    final dateStr = payload['date'] as String? ?? '';
    final date = DateTime.tryParse(dateStr) ?? DateTime.now();
    final type = payload['type'] as String? ?? 'receipt';

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.purpleAccent),
              SizedBox(width: 8),
              QaydText(title, slot: QaydTextStyleSlot.labelLarge),
            ],
          ),
          SizedBox(height: SpacingTokens.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              QaydMoneyDisplay(
                money: Money.nonNegative(
                  amount,
                  CurrencyCode(
                    code: currency,
                    nameAr: '',
                    symbol: '',
                    fractionalDigits: currencyDigits,
                  ),
                ),
                size: QaydMoneyDisplaySize.large,
              ),
              QaydText(
                type == 'receipt' ? AppStrings.catchStr : AppStrings.exchange,
                color: type == 'receipt'
                    ? Colors.greenAccent
                    : Colors.orangeAccent,
              ),
            ],
          ),
          SizedBox(height: 8),
          QaydText(
            DateFormat.yMMMd('ar').format(date),
            slot: QaydTextStyleSlot.bodySmall,
            color: Colors.white60,
          ),
        ],
      ),
    );
  }
}
