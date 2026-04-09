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
                  fillColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
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
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final a = filtered[i];
                  return ListTile(
                    title: QaydText(
                      a.name,
                      slot: QaydTextStyleSlot.bodyLarge,
                    ),
                    subtitle: a.isRoot
                        ? QaydText(
                            AppStringsAr.accountTypeRoot,
                            slot: QaydTextStyleSlot.bodySmall,
                          )
                        : null,
                    onTap: () => widget.onSelected(a),
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
