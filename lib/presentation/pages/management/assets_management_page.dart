import 'package:flutter/material.dart';
import 'package:qayd/application/accounts/dtos/list_accounts_input.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/pages/management/asset_creation_wizard_page.dart';
import 'package:qayd/presentation/pages/management/widgets/personal_accounts_list_view.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/widgets/qayd_scaffold.dart';

class AssetsManagementPage extends StatefulWidget {
  const AssetsManagementPage({super.key});

  @override
  State<AssetsManagementPage> createState() => _AssetsManagementPageState();
}

class _AssetsManagementPageState extends State<AssetsManagementPage> {
  String? _depreciableAssetsRootId;
  String? _profitableAssetsRootId;
  bool _isLoadingRoots = true;

  @override
  void initState() {
    super.initState();
    _loadRoots();
  }

  Future<void> _loadRoots() async {
    final result = await InjectionContainer.listAccountsUseCase(
      const ListAccountsInput(activeOnly: false),
    );
    result.fold(
      (_) => setState(() => _isLoadingRoots = false),
      (out) {
        for (final a in out.accounts) {
          if (a.isRoot) {
            if (a.standardClassificationKind == 'fixedDepreciableAssets') {
              _depreciableAssetsRootId = a.id;
            } else if (a.standardClassificationKind == 'fixedProfitableAssets') {
              _profitableAssetsRootId = a.id;
            }
          }
        }
        setState(() => _isLoadingRoots = false);
      },
    );
  }

  Future<void> _openWizard() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AssetCreationWizardPage(
          depreciableAssetsRootId: _depreciableAssetsRootId,
          profitableAssetsRootId: _profitableAssetsRootId,
        ),
      ),
    );
    if (updated == true) {
      setState(() {}); // Trigger rebuild to refresh list
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.extension<QaydCustomColors>()!.goldAccent;

    return QaydScaffold(
      appBar: QaydAppBar(
        title: AppStringsAr.managementTabAssets,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openWizard,
        icon: const Icon(Icons.add_business_rounded),
        label: const Text(AppStringsAr.managementAddAssetFab),
        backgroundColor: gold,
        foregroundColor: Colors.black,
      ),
      body: _isLoadingRoots
          ? const Center(child: CircularProgressIndicator())
          : const PersonalAccountsListView(
              kinds: ['fixedDepreciableAssets', 'fixedProfitableAssets'],
              emptyText: AppStringsAr.managementAssetsEmpty,
              showAssetDetails: true,
            ),
    );
  }
}
