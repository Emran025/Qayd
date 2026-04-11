import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/pages/accounts/archived_accounts_cubit.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';

class ArchivedAccountsPage extends StatelessWidget {
  const ArchivedAccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const QaydAppBar(title: AppStringsAr.archivedAccountsTitle),
      body: BlocBuilder<ArchivedAccountsCubit, ArchivedAccountsState>(
        builder: (context, state) {
          if (state is ArchivedAccountsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ArchivedAccountsFailure) {
            return Center(child: Text(state.failure.messageAr));
          }
          if (state is ArchivedAccountsReady) {
            final accounts = state.data.accounts;
            if (accounts.isEmpty) {
              return const Center(
                child: QaydText(AppStringsAr.archivedAccountsEmpty, slot: QaydTextStyleSlot.bodyLarge),
              );
            }
            return ListView.separated(
              itemCount: accounts.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final account = accounts[index];
                return ListTile(
                  title: QaydText(account.name, slot: QaydTextStyleSlot.titleMedium),
                  subtitle: Text(account.customClassificationName ?? account.standardClassificationKind ?? ''),
                  trailing: TextButton.icon(
                    icon: const Icon(Icons.unarchive_outlined),
                    label: const Text(AppStringsAr.restoreAccountAction),
                    onPressed: () => _confirmRestore(context, account.id, account.name),
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _confirmRestore(BuildContext context, String accountId, String accountName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStringsAr.restoreAccountTitle),
        content: Text(AppStringsAr.restoreAccountWarning(accountName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStringsAr.actionCancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ArchivedAccountsCubit>().restore(
                accountId,
                (error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error))),
                () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStringsAr.restoreAccountSuccess))),
              );
            },
            child: const Text(AppStringsAr.restoreAccountConfirm),
          ),
        ],
      ),
    );
  }
}
