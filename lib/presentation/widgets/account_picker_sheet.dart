import 'package:flutter/material.dart';
import 'package:qayd/application/accounts/dtos/account_summary_dto.dart';
import 'package:qayd/application/accounts/dtos/list_accounts_input.dart';
import 'package:qayd/application/accounts/list_accounts_use_case.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

/// Modal list of active accounts; returns selected account row.
Future<AccountSummaryDto?> showAccountPickerSheet(
  BuildContext context, {
  required ListAccountsUseCase listAccounts,
  String? excludeAccountId,
  bool rootAllowed = true,
  bool requireNoRoot = false,
  bool onlyRoots = false,
  String? requireParentClassification,
  List<String>? allowedClassifications,
  bool hideSterileRoots = false,
}) async {
  // Define sterile roots that should not have branches/children (per product requirements)
  const sterileClassifications = [
    'personalExpenses',
    'personalRevenues',
    'clearingRemittances',
    'liquidAssets',
  ];

  final result = await listAccounts(const ListAccountsInput(activeOnly: true));
  if (!context.mounted) {
    return null;
  }
  if (result.isFailure) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.failureOrNull!.messageAr)),
    );
    return null;
  }
  // Map parent standard classification to child
  final roots = result.valueOrNull!.accounts.where((a) => a.isRoot).toList();
  final classMap = {for (final r in roots) r.id: r.standardClassificationKind};

  final accounts = result.valueOrNull!.accounts.where((a) {
    if (a.id == excludeAccountId) return false;
    if (requireNoRoot && a.isRoot) return false;
    if (!rootAllowed && a.isRoot) return false;
    if (onlyRoots && !a.isRoot) return false;

    // Sterile roots filtering logic
    if (hideSterileRoots && a.isRoot) {
      if (sterileClassifications.contains(a.standardClassificationKind)) {
        return false;
      }
    }

    if (requireParentClassification != null) {
      if (a.isRoot) {
        if (a.standardClassificationKind != requireParentClassification)
          return false;
      } else {
        if (a.parentId != null) {
          final pClass = classMap[a.parentId!];
          if (pClass != requireParentClassification) return false;
        } else {
          return false;
        }
      }
    }

    if (allowedClassifications != null) {
      String? currentClass;
      if (a.isRoot) {
        currentClass = a.standardClassificationKind;
      } else if (a.parentId != null) {
        currentClass = classMap[a.parentId!];
      }
      if (currentClass == null ||
          !allowedClassifications.contains(currentClass)) {
        return false;
      }
    }

    return true;
  }).toList(growable: false);
  if (!context.mounted) {
    return null;
  }
  return showModalBottomSheet<AccountSummaryDto>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return _AccountPickerContent(
        accounts: accounts,
        onSelected: (a) => Navigator.of(ctx).pop(a),
      );
    },
  );
}

class _AccountPickerContent extends StatefulWidget {
  const _AccountPickerContent({
    required this.accounts,
    required this.onSelected,
  });

  final List<AccountSummaryDto> accounts;
  final ValueChanged<AccountSummaryDto> onSelected;

  @override
  State<_AccountPickerContent> createState() => _AccountPickerContentState();
}

class _AccountPickerContentState extends State<_AccountPickerContent> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final h = MediaQuery.sizeOf(context).height * 0.7;
    final filtered = widget.accounts.where((a) {
      if (_query.isEmpty) return true;
      return a.name.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: SpacingTokens.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.md,
                vertical: SpacingTokens.sm,
              ),
              child: QaydText(
                AppStringsAr.pickAccountTitle,
                slot: QaydTextStyleSlot.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SpacingTokens.md,
                0,
                SpacingTokens.md,
                SpacingTokens.sm,
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: AppStringsAr.searchAccountsHint,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _query = '';
                            });
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: SpacingTokens.md,
                  ),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(SpacingTokens.sm),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            SizedBox(
              height: h,
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final a = filtered[i];

                  // Pick an icon based on classification
                  IconData icon;
                  Color iconColor;
                  switch (a.standardClassificationKind) {
                    case 'receivables':
                      icon = Icons.person_add_alt_1_rounded;
                      iconColor = Colors.blue;
                      break;
                    case 'payables':
                      icon = Icons.person_remove_alt_1_rounded;
                      iconColor = Colors.orange;
                      break;
                    case 'liquidAssets':
                      icon = Icons.account_balance_wallet_rounded;
                      iconColor = Colors.green;
                      break;
                    case 'personalExpenses':
                      icon = Icons.shopping_bag_rounded;
                      iconColor = Colors.red;
                      break;
                    case 'personalRevenues':
                      icon = Icons.trending_up_rounded;
                      iconColor = Colors.teal;
                      break;
                    case 'settlements':
                      icon = Icons.swap_horiz_rounded;
                      iconColor = Colors.purple;
                      break;
                    default:
                      icon = a.isRoot
                          ? Icons.folder_rounded
                          : Icons.account_circle_rounded;
                      iconColor = scheme.onSurfaceVariant;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.md,
                        vertical: SpacingTokens.xs,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(SpacingTokens.sm),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: iconColor, size: 20),
                      ),
                      title: QaydText(
                        a.name,
                        slot: QaydTextStyleSlot.bodyLarge,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: QaydText(
                        a.isRoot
                            ? AppStringsAr.accountTypeRoot
                            : (a.standardClassificationKind != null
                                ? AppStringsAr.standardClassificationLabel(
                                    a.standardClassificationKind!)
                                : ''),
                        slot: QaydTextStyleSlot.bodySmall,
                        color: scheme.onSurfaceVariant,
                      ),
                      trailing: Icon(
                        Icons.chevron_left_rounded,
                        color: scheme.primary.withValues(alpha: 0.4),
                      ), // Arabic RTL
                      onTap: () => widget.onSelected(a),
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
