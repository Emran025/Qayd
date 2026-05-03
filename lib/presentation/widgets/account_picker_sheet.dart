import 'package:flutter/material.dart';
import 'package:qayd/application/accounts/dtos/account_summary_dto.dart';
import 'package:qayd/application/accounts/dtos/list_accounts_input.dart';
import 'package:qayd/application/accounts/list_accounts_use_case.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/domain/repositories/identity_repository.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/value_objects/account_id.dart';

import 'package:url_launcher/url_launcher.dart';

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
  bool showIdentityStatus = false,
  String? initialSearchQuery,
}) async {
  final data = await _loadAndFilterAccounts(
    context,
    listAccounts: listAccounts,
    excludeAccountId: excludeAccountId,
    rootAllowed: rootAllowed,
    requireNoRoot: requireNoRoot,
    onlyRoots: onlyRoots,
    requireParentClassification: requireParentClassification,
    allowedClassifications: allowedClassifications,
    hideSterileRoots: hideSterileRoots,
  );

  if (data == null || !context.mounted) return null;

  return showModalBottomSheet<AccountSummaryDto>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return _AccountPickerContent(
        accounts: data.accounts,
        parentNames: data.parentNames,
        showIdentityStatus: showIdentityStatus,
        initialSearchQuery: initialSearchQuery,
        onSelected: (a) => Navigator.of(ctx).pop(a),
      );
    },
  );
}

/// Modal list of active accounts supporting multiple selection.
Future<List<AccountSummaryDto>?> showMultiAccountPickerSheet(
  BuildContext context, {
  required ListAccountsUseCase listAccounts,
  String? excludeAccountId,
  bool rootAllowed = true,
  bool requireNoRoot = false,
  bool onlyRoots = false,
  String? requireParentClassification,
  List<String>? allowedClassifications,
  bool hideSterileRoots = false,
  List<String>? initialSelectedIds,
  bool showIdentityStatus = false,
  String? initialSearchQuery,
}) async {
  final data = await _loadAndFilterAccounts(
    context,
    listAccounts: listAccounts,
    excludeAccountId: excludeAccountId,
    rootAllowed: rootAllowed,
    requireNoRoot: requireNoRoot,
    onlyRoots: onlyRoots,
    requireParentClassification: requireParentClassification,
    allowedClassifications: allowedClassifications,
    hideSterileRoots: hideSterileRoots,
  );

  if (data == null || !context.mounted) return null;

  return showModalBottomSheet<List<AccountSummaryDto>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return _AccountPickerContent(
        accounts: data.accounts,
        parentNames: data.parentNames,
        isMultiSelect: true,
        initialSelectedIds: initialSelectedIds,
        showIdentityStatus: showIdentityStatus,
        initialSearchQuery: initialSearchQuery,
        onMultiSelected: (list) => Navigator.of(ctx).pop(list),
      );
    },
  );
}

class _PickerData {
  final List<AccountSummaryDto> accounts;
  final Map<String, String> parentNames;
  const _PickerData(this.accounts, this.parentNames);
}

Future<_PickerData?> _loadAndFilterAccounts(
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
  final parentNamesMap = {for (final r in roots) r.id: r.name};

  final filteredAccounts = result.valueOrNull!.accounts.where((a) {
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
        if (a.standardClassificationKind != requireParentClassification) {
          return false;
        }
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

  return _PickerData(filteredAccounts, parentNamesMap);
}

class _AccountPickerContent extends StatefulWidget {
  const _AccountPickerContent({
    required this.accounts,
    required this.parentNames,
    this.onSelected,
    this.onMultiSelected,
    this.isMultiSelect = false,
    this.initialSelectedIds,
    this.showIdentityStatus = false,
    this.initialSearchQuery,
  });

  final List<AccountSummaryDto> accounts;
  final Map<String, String> parentNames;
  final ValueChanged<AccountSummaryDto>? onSelected;
  final ValueChanged<List<AccountSummaryDto>>? onMultiSelected;
  final bool isMultiSelect;
  final List<String>? initialSelectedIds;
  final bool showIdentityStatus;
  final String? initialSearchQuery;

  @override
  State<_AccountPickerContent> createState() => _AccountPickerContentState();
}

class _AccountPickerContentState extends State<_AccountPickerContent> {
  final _searchController = TextEditingController();
  late String _query;
  late final Set<String> _selectedIds;
  final Map<String, PublicKeyLookupResult> _identityMap = {};
  bool _isCheckingIdentities = false;

  @override
  void initState() {
    super.initState();
    _query = widget.initialSearchQuery ?? '';
    _searchController.text = _query;
    _selectedIds = Set.from(widget.initialSelectedIds ?? []);
    if (widget.showIdentityStatus) {
      _lookupIdentities();
    }
  }

  Future<void> _lookupIdentities() async {
    if (widget.accounts.isEmpty) return;

    setState(() => _isCheckingIdentities = true);

    try {
      final List<String> phones = [];
      final Map<String, String> accountIdToPhone = {};

      // 1. Fetch party details for each account to get phone numbers
      for (final acc in widget.accounts) {
        if (acc.isRoot) continue;
        final result = await InjectionContainer.accountRepository
            .getPartyDetails(AccountId(acc.id));
        final party = result.valueOrNull;
        final phone =
            (party?.phoneNumber?.trim() ?? party?.whatsappNumber?.trim() ?? '')
                .replaceAll(RegExp(r'\s+'), '');

        if (phone.isNotEmpty) {
          phones.add(phone);
          accountIdToPhone[acc.id] = phone;
        }
      }

      if (phones.isEmpty) {
        setState(() => _isCheckingIdentities = false);
        return;
      }

      // 2. Perform batch lookup on server
      final results = await InjectionContainer.identityRepository
          .lookupBatch(phones: phones);

      if (mounted) {
        setState(() {
          // Map results back to account IDs
          for (final entry in accountIdToPhone.entries) {
            final res = results[entry.value];
            if (res != null) {
              _identityMap[entry.key] = res;
            } else {
              // Not found on server
              _identityMap[entry.key] = PublicKeyLookupResult(
                phone: entry.value,
                name: '',
                isRegistered: false,
              );
            }
          }
          _isCheckingIdentities = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingIdentities = false);
      }
    }
  }

  void _inviteAccount(AccountSummaryDto account) {
    final phone = _identityMap[account.id]?.phone;
    if (phone == null || phone.isEmpty) return;

    final message =
        'مرحباً ${account.name}، أدعوك لاستخدام تطبيق AppStringsAr.restriction للمحاسبة والمزامنة السحابية.';
    final uri = Uri.parse(
        'whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}');
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getAccountSubtitle(AccountSummaryDto a) {
    if (a.isRoot) {
      return AppStringsAr.accountTypeRoot;
    }

    // Attempt to find the direct parent's name
    if (a.parentId != null) {
      final parentName = widget.parentNames[a.parentId];
      if (parentName != null) {
        return parentName;
      }
    }

    // Fallback to standard classification
    if (a.standardClassificationKind != null) {
      final label =
          AppStringsAr.standardClassificationLabel(a.standardClassificationKind!);
      final phone = a.metadata?['phone'] ?? a.metadata?['whatsapp'];
      if (phone != null) {
        return '$label • $phone';
      }
      return label;
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final h = MediaQuery.sizeOf(context).height * 0.7;
    final filtered = widget.accounts.where((a) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      if (a.name.toLowerCase().contains(q)) return true;

      // Also search in phone/whatsapp metadata
      final phone = a.metadata?['phone']?.toString().toLowerCase();
      if (phone != null && phone.contains(q)) return true;

      final whatsapp = a.metadata?['whatsapp']?.toString().toLowerCase();
      if (whatsapp != null && whatsapp.contains(q)) return true;

      return false;
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
            if (_isCheckingIdentities)
              const LinearProgressIndicator(minHeight: 2),
            if (widget.isMultiSelect)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.md,
                  vertical: SpacingTokens.xs,
                ),
                child: FilledButton.icon(
                  onPressed: () {
                    final selected = widget.accounts
                        .where((a) => _selectedIds.contains(a.id))
                        .toList();
                    widget.onMultiSelected?.call(selected);
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: const Text(AppStringsAr.confirmSelection),
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
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          QaydText(
                            _getAccountSubtitle(a),
                            slot: QaydTextStyleSlot.bodySmall,
                            color: scheme.onSurfaceVariant,
                          ),
                          if (widget.showIdentityStatus &&
                              _identityMap.containsKey(a.id)) ...[
                            const SizedBox(height: 4),
                            _buildIdentityStatus(
                                context, _identityMap[a.id]!, a),
                          ],
                        ],
                      ),
                      trailing: widget.isMultiSelect
                          ? Checkbox.adaptive(
                              value: _selectedIds.contains(a.id),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedIds.add(a.id);
                                  } else {
                                    _selectedIds.remove(a.id);
                                  }
                                });
                              },
                            )
                          : Icon(
                              Icons.chevron_left_rounded,
                              color: scheme.primary.withValues(alpha: 0.4),
                            ), // Arabic RTL
                      onTap: () {
                        if (widget.isMultiSelect) {
                          setState(() {
                            if (_selectedIds.contains(a.id)) {
                              _selectedIds.remove(a.id);
                            } else {
                              _selectedIds.add(a.id);
                            }
                          });
                        } else {
                          widget.onSelected?.call(a);
                        }
                      },
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

  Widget _buildIdentityStatus(BuildContext context, PublicKeyLookupResult res,
      AccountSummaryDto account) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (!res.isRegistered) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              AppStringsAr.notRegistered,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _inviteAccount(account),
            child: Text(
              AppStringsAr.callNow,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: scheme.primary,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      );
    }

    if (res.syncBlocked) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_person_outlined, size: 12, color: scheme.secondary),
          const SizedBox(width: 4),
          Text(
            AppStringsAr.privacyProtected,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 9,
              color: scheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified_user_rounded, size: 12, color: scheme.primary),
        const SizedBox(width: 4),
        Text(
          AppStringsAr.readyToSync,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 9,
            color: scheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
