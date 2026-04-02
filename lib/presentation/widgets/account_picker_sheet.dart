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
  String? requireParentClassification,
}) async {
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
  final classMap = {
    for (final r in roots)
      r.id: r.standardClassificationKind
  };

  final accounts = result.valueOrNull!.accounts.where((a) {
    if (a.id == excludeAccountId) return false;
    if (requireNoRoot && a.isRoot) return false;
    if (!rootAllowed && a.isRoot) return false;
    
    if (requireParentClassification != null) {
      if (a.isRoot) {
         if (a.standardClassificationKind != requireParentClassification) return false;
      } else {
         if (a.parentId != null) {
           final pClass = classMap[a.parentId!];
           if (pClass != requireParentClassification) return false;
         } else {
           return false;
         }
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
      final h = MediaQuery.sizeOf(ctx).height * 0.55;
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
              SizedBox(
                height: h,
                child: ListView.builder(
                  itemCount: accounts.length,
                  itemBuilder: (context, i) {
                    final a = accounts[i];
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
                      onTap: () => Navigator.of(context).pop(a),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
