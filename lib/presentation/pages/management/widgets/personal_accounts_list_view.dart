import 'package:flutter/material.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/application/accounts/dtos/account_summary_dto.dart';
import 'package:qayd/application/accounts/dtos/list_accounts_input.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/pages/cost_centers/cost_center_dashboard_widgets.dart'; // Contains GlassCard
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/pages/management/income_stream_detail_page.dart';
import 'package:qayd/presentation/navigation/qayd_page_route.dart';

class PersonalAccountsListView extends StatefulWidget {
  const PersonalAccountsListView({
    super.key,
    required this.kinds,
    required this.emptyText,
    this.showAssetDetails = false,
    this.searchText = '',
  });

  final List<String> kinds;
  final String emptyText;
  final bool showAssetDetails;
  final String searchText;

  @override
  State<PersonalAccountsListView> createState() =>
      _PersonalAccountsListViewState();
}

class _PersonalAccountsListViewState extends State<PersonalAccountsListView> {
  bool _loading = true;
  List<AccountSummaryDto> _accounts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(PersonalAccountsListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kinds != widget.kinds ||
        oldWidget.searchText != widget.searchText) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await InjectionContainer.listAccountsUseCase(
      const ListAccountsInput(activeOnly: false),
    );
    res.fold(
      (_) => setState(() => _loading = false),
      (data) {
        setState(() {
          _accounts = data.accounts.where((a) {
            final matchesKind =
                widget.kinds.contains(a.standardClassificationKind);
            final isChild = a.parentId != null;
            final matchesSearch = widget.searchText.isEmpty ||
                a.name.toLowerCase().contains(widget.searchText.toLowerCase());

            return matchesKind && isChild && matchesSearch;
          }).toList();
          _loading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Center(child: CircularProgressIndicator());
    if (_accounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 48, color: Theme.of(context).colorScheme.outline),
            SizedBox(height: SpacingTokens.md),
            QaydText(
              widget.emptyText,
              color: Theme.of(context).colorScheme.outline,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(SpacingTokens.md),
      itemCount: _accounts.length,
      itemBuilder: (ctx, i) {
        final a = _accounts[i];
        final metadata = a.metadata ?? {};

        final price = metadata['purchase_price'] ?? 0.0;
        final date = metadata['purchase_date'] as String?;
        final serial = metadata['serial_number'] as String?;
        final model = metadata['model'] as String?;

        // Format balance
        int balanceMinor = 0;
        String cur = metadata['currency_code'] as String? ?? '';
        if (a.balancesMinorUnits.isNotEmpty) {
          cur = a.balancesMinorUnits.keys.first;
          balanceMinor = a.balancesMinorUnits[cur]!;
        }
        final balance = balanceMinor / 100.0;
        final balanceText = cur.isNotEmpty
            ? '${balance.toStringAsFixed(2)} $cur'
            : balance.toStringAsFixed(2);
        final purchaseCurrency =
            metadata['purchase_currency'] as String? ?? cur;

        return Container(
          margin: const EdgeInsets.only(bottom: SpacingTokens.md),
          child: GlassCard(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  await Navigator.of(context).push<void>(
                    QaydPageRoute.slideFromStart<void>(
                      builder: (ctx) => IncomeStreamDetailPage(summary: a),
                    ),
                  );
                  _load();
                },
                borderRadius: BorderRadius.circular(RadiusTokens.md),
                child: Padding(
                  padding: const EdgeInsets.all(SpacingTokens.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: QaydText(
                              a.name,
                              slot: QaydTextStyleSlot.titleMedium,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  ColorTokens.emerald400.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(RadiusTokens.pill),
                            ),
                            child: QaydText(
                              widget.showAssetDetails
                                  ? '${price.toStringAsFixed(2)} ${purchaseCurrency.isNotEmpty ? purchaseCurrency : ''}'
                                  : balanceText,
                              slot: QaydTextStyleSlot.labelSmall,
                              color: ColorTokens.emerald400,
                            ),
                          ),
                        ],
                      ),
                      if (widget.showAssetDetails &&
                          (model != null ||
                              serial != null ||
                              date != null)) ...[
                        SizedBox(height: SpacingTokens.sm),
                        if (model != null && model.isNotEmpty)
                          _InfoRow(
                              icon: Icons.directions_car_rounded,
                              label: AppStrings.modelLabel,
                              value: model),
                        if (serial != null && serial.isNotEmpty)
                          _InfoRow(
                              icon: Icons.numbers_rounded,
                              label: AppStrings.serialNumberLabel,
                              value: serial),
                        if (date != null)
                          _InfoRow(
                              icon: Icons.calendar_today_rounded,
                              label: AppStrings.purchaseDateLabel,
                              value: date.split('T').first),
                      ],
                      SizedBox(height: SpacingTokens.md),
                      const Divider(height: 1),
                      SizedBox(height: SpacingTokens.md),
                      Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 14, color: Colors.white54),
                          SizedBox(width: 4),
                          Text(
                            a.isActive ? AppStrings.statusActiveEn : AppStrings.statusInactiveEn,
                            style: TextStyle(
                              fontSize: 10,
                              color: a.isActive
                                  ? ColorTokens.emerald400
                                  : Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white54),
          SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
