import 'package:flutter/material.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/application/accounts/dtos/account_summary_dto.dart';
import 'package:qayd/application/accounts/dtos/list_accounts_input.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/pages/cost_centers/cost_center_dashboard_widgets.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

class AssetsListView extends StatefulWidget {
  const AssetsListView({super.key});

  @override
  State<AssetsListView> createState() => _AssetsListViewState();
}

class _AssetsListViewState extends State<AssetsListView> {
  bool _loading = true;
  List<AccountSummaryDto> _assets = [];

  @override
  void initState() {
    super.initState();
    _load();
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
          _assets = data.accounts
              .where((a) =>
                  a.standardClassificationKind == 'fixedDepreciableAssets' ||
                  a.standardClassificationKind == 'fixedProfitableAssets')
              .toList();
          _loading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_assets.isEmpty) {
      return const Center(child: QaydText(AppStringsAr.assetsEmptyList));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(SpacingTokens.md),
      itemCount: _assets.length,
      itemBuilder: (ctx, i) {
        final asset = _assets[i];
        final metadata = asset.metadata ?? {};
        final price = metadata['purchase_price'] ?? 0.0;
        final date = metadata['purchase_date'] as String?;
        final serial = metadata['serial_number'] as String?;
        final model = metadata['model'] as String?;

        return Container(
          margin: const EdgeInsets.only(bottom: SpacingTokens.md),
          child: GlassCard(
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
                          asset.name,
                          slot: QaydTextStyleSlot.titleMedium,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: ColorTokens.emerald400.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(RadiusTokens.pill),
                        ),
                        child: QaydText(
                          '${price.toStringAsFixed(2)} SAR',
                          slot: QaydTextStyleSlot.labelSmall,
                          color: ColorTokens.emerald400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SpacingTokens.sm),
                  if (model != null && model.isNotEmpty)
                    _InfoRow(
                        icon: Icons.directions_car_rounded,
                        label: AppStringsAr.modelLabel,
                        value: model),
                  if (serial != null && serial.isNotEmpty)
                    _InfoRow(
                        icon: Icons.numbers_rounded,
                        label: AppStringsAr.serialNumberOrPlateLabel,
                        value: serial),
                  if (date != null)
                    _InfoRow(
                        icon: Icons.calendar_today_rounded,
                        label: AppStringsAr.purchaseDateLabel,
                        value: date.split('T').first),
                  const SizedBox(height: SpacingTokens.md),
                  const Divider(height: 1),
                  const SizedBox(height: SpacingTokens.md),
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 14, color: Colors.white54),
                      const SizedBox(width: 4),
                      Text(
                        asset.isActive ? AppStringsAr.statusActiveEn : AppStringsAr.statusInactiveEn,
                        style: TextStyle(
                          fontSize: 10,
                          color: asset.isActive
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
          const SizedBox(width: 8),
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
