import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/pages/accounts/statement_chat_cubit.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qayd/application/accounts/dtos/get_account_details_output.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/predefined_currencies.dart';
import 'package:qayd/presentation/components/atomic/qayd_money_display.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/navigation/qayd_page_route.dart';
import 'package:qayd/presentation/pages/accounts/account_create_page.dart';
import 'package:qayd/presentation/pages/accounts/account_create_cubit.dart';
import 'package:qayd/presentation/pages/accounts/account_detail_cubit.dart';
import 'package:qayd/presentation/pages/accounts/account_edit_cubit.dart';
import 'package:qayd/presentation/pages/messaging/notification_preview_mode.dart';
import 'package:qayd/presentation/pages/messaging/notification_preview_page.dart';
import 'package:qayd/presentation/pages/accounts/widgets/account_default_cost_centers_section.dart';
import 'package:qayd/presentation/utils/account_statement_pdf_export.dart';
import 'package:qayd/presentation/utils/account_archive_helper.dart';
import 'package:qayd/presentation/pages/accounts/account_statement_chat_page.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

class AccountDetailPage extends StatelessWidget {
  const AccountDetailPage({super.key});

  Future<void> _openEdit(
    BuildContext context,
    GetAccountDetailsOutput data,
  ) async {
    final cubit = context.read<AccountDetailCubit>();
    final refreshed = await Navigator.of(context).push<bool>(
      QaydPageRoute.slideFromStart<bool>(
        builder: (ctx) => MultiBlocProvider(
          providers: [
            // AccountCreateCubit is still required by the page's create-mode
            // BlocConsumer, even though it won't be called in edit mode.
            BlocProvider(
              create: (_) => AccountCreateCubit(
                InjectionContainer.createAccountUseCase,
              ),
            ),
            BlocProvider(
              create: (_) => AccountEditCubit(
                InjectionContainer.updateAccountUseCase,
              ),
            ),
          ],
          child: AccountCreatePage(editData: data),
        ),
      ),
    );
    if (refreshed == true && context.mounted) {
      cubit.load(data.accountId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountDetailCubit, AccountDetailState>(
      builder: (context, state) {
        final scheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: QaydAppBar(
            title: state is AccountDetailReady
                ? state.data.name
                : AppStringsAr.accountDetailTitle,
            actions: [
              if (state is AccountDetailReady) ...[
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  color: scheme.surface,
                  surfaceTintColor: Colors.transparent,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(RadiusTokens.md),
                    side: BorderSide(
                      color: scheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _openEdit(context, state.data);
                        break;
                      case 'message':
                        Navigator.of(context).push<void>(
                          QaydPageRoute.slideFromStart<void>(
                            builder: (ctx) => NotificationPreviewPage(
                              mode: NotificationPreviewAccount(
                                  state.data.accountId),
                            ),
                          ),
                        );
                        break;
                      case 'chat':
                        Navigator.of(context).push<void>(
                          QaydPageRoute.slideFromStart<void>(
                            builder: (ctx) => BlocProvider(
                              create: (_) => StatementChatCubit(
                                listStatement: InjectionContainer
                                    .listAccountStatementChatUseCase,
                                listAccounts:
                                    InjectionContainer.listAccountsUseCase,
                                getCostCenterDetails: InjectionContainer
                                    .getCostCenterDetailsUseCase,
                                counterpartyAccountId: state.data.accountId,
                              )..load(),
                              child: AccountStatementChatPage(
                                counterpartyAccountId: state.data.accountId,
                              ),
                            ),
                          ),
                        );
                        break;
                      case 'export_pdf':
                        shareAccountStatementAsPdf(
                          context,
                          accountId: state.data.accountId,
                        );
                        break;
                      case 'refresh':
                        context
                            .read<AccountDetailCubit>()
                            .load(state.data.accountId);
                        break;
                      case 'archive':
                        confirmAndArchiveAccount(context, state.data.accountId);
                        break;
                    }
                  },
                  itemBuilder: (context) {
                    final scheme = Theme.of(context).colorScheme;
                    return [
                      _buildMenuItem(
                        value: 'edit',
                        icon: Icons.edit_outlined,
                        label: AppStringsAr.editAccountTooltip,
                        iconColor: scheme.primary,
                      ),
                      _buildMenuItem(
                        value: 'message',
                        icon: Icons.chat_bubble_outline_rounded,
                        label: AppStringsAr.accountSendMessageTooltip,
                        iconColor: Colors.blueAccent,
                      ),
                      _buildMenuItem(
                        value: 'chat',
                        icon: Icons.forum_outlined,
                        label: AppStringsAr.accountStatementConversation,
                        iconColor: Colors.teal,
                      ),
                      _buildMenuItem(
                        value: 'export_pdf',
                        icon: Icons.picture_as_pdf_outlined,
                        label: AppStringsAr.accountStatementExportPdfTooltip,
                        iconColor: Colors.redAccent,
                      ),
                      const PopupMenuDivider(),
                      _buildMenuItem(
                        value: 'refresh',
                        icon: Icons.refresh_rounded,
                        label: AppStringsAr.refreshBalanceTooltip,
                        iconColor: scheme.onSurfaceVariant,
                      ),
                      _buildMenuItem(
                        value: 'archive',
                        icon: Icons.archive_outlined,
                        label: AppStringsAr.archiveAccountAction,
                        iconColor: scheme.error,
                      ),
                    ];
                  },
                ),
              ],
            ],
          ),
          body: switch (state) {
            AccountDetailInitial() || AccountDetailLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            AccountDetailFailure(:final failure) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(SpacingTokens.lg),
                  child: QaydText(
                    failure.messageAr,
                    slot: QaydTextStyleSlot.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            AccountDetailReady(:final data) => _DetailBody(data: data),
          },
        );
      },
    );
  }

  PopupMenuItem<String> _buildMenuItem({
    required String value,
    required IconData icon,
    required String label,
    required Color iconColor,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: SpacingTokens.md),
          QaydText(label, slot: QaydTextStyleSlot.bodyMedium),
        ],
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.data});

  final GetAccountDetailsOutput data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final custom = theme.extension<QaydCustomColors>()!;
    final created =
        intl.DateFormat.yMMMd('ar').format(DateTime.parse(data.createdAtIso));

    final classificationText = data.standardClassificationKind != null
        ? AppStringsAr.standardClassificationLabel(
            data.standardClassificationKind!)
        : data.customClassificationName ?? AppStringsAr.classificationOther;

    final natureDebit = data.natureCode == 'debit';
    final natureColor = natureDebit ? custom.debit : custom.credit;
    final natureLabel = natureDebit
        ? AppStringsAr.natureDebitShort
        : AppStringsAr.natureCreditShort;

    final iconData = _getAccountIcon(data.standardClassificationKind);

    return ListView(
      padding: const EdgeInsets.all(SpacingTokens.md),
      children: [
        // ── 1. Clean Balance Header ──
        Container(
          margin: const EdgeInsets.only(bottom: SpacingTokens.lg),
          padding: const EdgeInsets.all(SpacingTokens.xl),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(RadiusTokens.lg),
            border:
                Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: natureColor.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: natureColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(RadiusTokens.pill),
                  border: Border.all(color: natureColor.withValues(alpha: 0.2)),
                ),
                child: QaydText(
                  natureLabel,
                  slot: QaydTextStyleSlot.labelSmall,
                  color: natureColor,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
              const SizedBox(height: SpacingTokens.md),
              if (data.balancesMinorUnits.isEmpty)
                QaydMoneyDisplay(
                  money: Money.zero(PredefinedCurrencies.sar),
                  size: QaydMoneyDisplaySize.large,
                )
              else
                ...data.balancesMinorUnits.entries.map((e) {
                  final code = e.key;
                  final minor = e.value;
                  return QaydMoneyDisplay(
                    money: Money.nonNegative(
                        minor.abs(),
                        PredefinedCurrencies.all.firstWhere(
                            (c) => c.code == code,
                            orElse: () => CurrencyCode(
                                code: code, nameAr: code, symbol: code))),
                    displayNegative: minor < 0,
                    size: QaydMoneyDisplaySize.large,
                  );
                }),
              const SizedBox(height: SpacingTokens.xs),
              QaydText(
                AppStringsAr.accountBalanceLabel,
                slot: QaydTextStyleSlot.labelSmall,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),

        // ── 2. Information Cards ──
        _SectionHeader(
            title: AppStringsAr.accountId1,
            icon: Icons.fingerprint_rounded,
            color: ColorTokens.emerald600),
        const SizedBox(height: SpacingTokens.sm),
        _CardWrapper(
          child: Column(
            children: [
              _RichRow(
                icon: iconData,
                iconColor: ColorTokens.navy700,
                label: AppStringsAr.classificationLabel,
                value: classificationText,
              ),
              const _LineDivider(),
              _RichRow(
                icon: Icons.track_changes_rounded,
                iconColor: natureColor,
                label: AppStringsAr.natureLabel,
                value: natureLabel,
                valueColor: natureColor,
              ),
              const _LineDivider(),
              _RichRow(
                icon: Icons.verified_user_outlined,
                iconColor: data.isActive ? Colors.green : Colors.grey,
                label: AppStringsAr.statusLabel,
                value: data.isActive
                    ? AppStringsAr.statusActive
                    : AppStringsAr.statusInactive,
              ),
            ],
          ),
        ),

        const SizedBox(height: SpacingTokens.lg),
        _SectionHeader(
            title: AppStringsAr.chronologyAndDependency,
            icon: Icons.account_tree_outlined,
            color: ColorTokens.navy700),
        const SizedBox(height: SpacingTokens.sm),
        _CardWrapper(
          child: Column(
            children: [
              _RichRow(
                icon: Icons.layers_outlined,
                iconColor: scheme.primary,
                label: AppStringsAr.accountTypeLabel,
                value: data.isRoot
                    ? AppStringsAr.accountTypeRoot
                    : AppStringsAr.accountTypeChild,
              ),
              if (data.parentId != null) ...[
                const _LineDivider(),
                _RichRow(
                  icon: Icons.subdirectory_arrow_left_rounded,
                  iconColor: Colors.deepPurple,
                  label: AppStringsAr.parentAccountLabel,
                  value: data.parentName ?? data.parentId!,
                ),
              ],
              const _LineDivider(),
              _RichRow(
                icon: Icons.calendar_today_rounded,
                iconColor: Colors.blueGrey,
                label: AppStringsAr.createdAtLabel,
                value: created,
              ),
            ],
          ),
        ),

        // ── 3. Party Details Section ──
        if (data.phoneNumber != null || data.whatsappNumber != null) ...[
          const SizedBox(height: SpacingTokens.lg),
          _SectionHeader(
              title: AppStringsAr.partyDetailsSection,
              icon: Icons.contact_mail_outlined,
              color: ColorTokens.goldAccent),
          const SizedBox(height: SpacingTokens.sm),
          _CardWrapper(
            child: Column(
              children: [
                if (data.partyType?.isNotEmpty == true &&
                    data.partyType != null)
                  _RichRow(
                    icon: Icons.people_outline_rounded,
                    iconColor: Colors.indigo,
                    label: AppStringsAr.partyTypeLabel,
                    value: data.partyType!,
                  ),
                if (data.phoneNumber?.isNotEmpty == true)
                  _ActionRow(
                    icon: Icons.phone_android_rounded,
                    label: "+${data.phoneNumber!}",
                    actionLabel: AppStringsAr.actionCall,
                    color: Colors.blue.shade700,
                    onTap: () =>
                        launchUrl(Uri.parse('tel:+${data.phoneNumber}')),
                  ),
                if (data.whatsappNumber?.isNotEmpty == true)
                  _ActionRow(
                    icon: Icons.chat_rounded,
                    label: "+${data.whatsappNumber!}",
                    actionLabel: AppStringsAr.actionWhatsApp,
                    color: const Color(0xFF25D366),
                    onTap: () => launchUrl(
                        Uri.parse('https://wa.me/${data.whatsappNumber}')),
                  ),
                if (data.bankAccountInfo?.isNotEmpty == true &&
                    data.bankAccountInfo != null)
                  _ActionRow(
                    icon: Icons.credit_card_rounded,
                    label: data.bankAccountInfo!,
                    actionLabel: AppStringsAr.actionCopyBank,
                    color: ColorTokens.navy900,
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: data.bankAccountInfo!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(AppStringsAr.bankInfoCopied)),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: SpacingTokens.xl),
        // ── 4. Default Cost Centers Section ──
        AccountDefaultCostCentersSection(data: data),
        const SizedBox(height: SpacingTokens.xl),
      ],
    );
  }

  IconData _getAccountIcon(String? kind) {
    if (kind == null) return Icons.account_balance_wallet_rounded;
    return switch (kind) {
      'liquidAssets' => Icons.account_balance_rounded,
      'receivables' => Icons.trending_up_rounded,
      'payables' => Icons.trending_down_rounded,
      'settlements' => Icons.handshake_rounded,
      'equity' => Icons.pie_chart_rounded,
      'revenues' => Icons.monetization_on_rounded,
      'expenses' => Icons.receipt_long_rounded,
      _ => Icons.folder_rounded,
    };
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
      {required this.title, required this.icon, required this.color});
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          QaydText(
            title,
            slot: QaydTextStyleSlot.labelLarge,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _CardWrapper extends StatelessWidget {
  const _CardWrapper({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(RadiusTokens.md),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LineDivider extends StatelessWidget {
  const _LineDivider();
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 48,
      endIndent: 16,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
    );
  }
}

class _RichRow extends StatelessWidget {
  const _RichRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.sm + 2,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor ?? scheme.onSurfaceVariant),
          const SizedBox(width: SpacingTokens.md),
          Expanded(
            child: QaydText(
              label,
              slot: QaydTextStyleSlot.bodyMedium,
              color: scheme.onSurfaceVariant,
            ),
          ),
          QaydText(
            value,
            slot: QaydTextStyleSlot.labelLarge,
            color: valueColor ?? scheme.onSurface,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.actionLabel,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final String actionLabel;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md,
          vertical: SpacingTokens.sm + 2,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? scheme.primary),
            const SizedBox(width: SpacingTokens.md),
            Expanded(
              child: QaydText(
                label,
                slot: QaydTextStyleSlot.bodyMedium,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: (color ?? scheme.primary).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(RadiusTokens.md),
              ),
              child: Text(
                actionLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: color ?? scheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
