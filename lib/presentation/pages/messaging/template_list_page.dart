import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/entities/message_template.dart';
import 'package:qayd/domain/value_objects/message_template_kind.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/pages/messaging/template_list_cubit.dart';
import 'package:qayd/presentation/pages/messaging/template_list_state.dart';
import 'package:qayd/presentation/pages/settings/settings_app_bar_action.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

class NotificationTemplatesPage extends StatelessWidget {
  const NotificationTemplatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TemplateListCubit(
        InjectionContainer.listMessageTemplatesUseCase,
        InjectionContainer.saveMessageTemplateUseCase,
        InjectionContainer.deleteMessageTemplateUseCase,
      )..load(),
      child: const _TemplateListScaffold(),
    );
  }
}

class _TemplateListScaffold extends StatelessWidget {
  const _TemplateListScaffold();

  Future<void> _openCreate(BuildContext context) async {
    var kind = MessageTemplateKind.receipt;
    final nameCtrl = TextEditingController();
    final bodyCtrl = TextEditingController(
      text: 'عزيزي {{customer}}،\n',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: QaydText(
              AppStringsAr.templateAddTitle,
              slot: QaydTextStyleSlot.titleLarge,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<MessageTemplateKind>(
                    value: kind,
                    decoration: InputDecoration(
                      labelText: AppStringsAr.templateKindPickerLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: MessageTemplateKind.receipt,
                        child: Text(AppStringsAr.templateKindReceipt),
                      ),
                      DropdownMenuItem(
                        value: MessageTemplateKind.payment,
                        child: Text(AppStringsAr.templateKindPayment),
                      ),
                      DropdownMenuItem(
                        value: MessageTemplateKind.accountBalance,
                        child: Text(AppStringsAr.templateKindAccount),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => kind = v);
                      }
                    },
                  ),
                  const SizedBox(height: SpacingTokens.md),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: AppStringsAr.templateNameLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.md),
                  TextField(
                    controller: bodyCtrl,
                    maxLines: 8,
                    decoration: InputDecoration(
                      labelText: AppStringsAr.templateBodyLabel,
                      border: const OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(AppStringsAr.templateEditCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(AppStringsAr.templateEditSave),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true || !context.mounted) {
      nameCtrl.dispose();
      bodyCtrl.dispose();
      return;
    }
    final name = nameCtrl.text.trim();
    final bodyText = bodyCtrl.text;
    nameCtrl.dispose();
    bodyCtrl.dispose();
    final r = await InjectionContainer.createMessageTemplateUseCase(
      kind: kind,
      name: name,
      body: bodyText,
    );
    if (!context.mounted) {
      return;
    }
    if (r.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r.failureOrNull!.messageAr)),
      );
      return;
    }
    await context.read<TemplateListCubit>().load();
  }

  String _kindLabel(MessageTemplateKind k) {
    return switch (k) {
      MessageTemplateKind.receipt => AppStringsAr.templateKindReceipt,
      MessageTemplateKind.payment => AppStringsAr.templateKindPayment,
      MessageTemplateKind.accountBalance => AppStringsAr.templateKindAccount,
    };
  }

  Future<void> _edit(
    BuildContext context,
    MessageTemplate t,
  ) async {
    final nameCtrl = TextEditingController(text: t.name);
    final bodyCtrl = TextEditingController(text: t.body);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: QaydText(
          AppStringsAr.templateEditTitle,
          slot: QaydTextStyleSlot.titleLarge,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: AppStringsAr.templateNameLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: SpacingTokens.md),
              TextField(
                controller: bodyCtrl,
                maxLines: 10,
                decoration: InputDecoration(
                  labelText: AppStringsAr.templateBodyLabel,
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStringsAr.templateEditCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppStringsAr.templateEditSave),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) {
      nameCtrl.dispose();
      bodyCtrl.dispose();
      return;
    }
    final updated = MessageTemplate(
      id: t.id,
      kind: t.kind,
      name: nameCtrl.text.trim(),
      body: bodyCtrl.text,
      isSystem: t.isSystem,
      sortOrder: t.sortOrder,
      createdAt: t.createdAt,
      updatedAt: DateTime.now(),
    );
    nameCtrl.dispose();
    bodyCtrl.dispose();
    final r = await context.read<TemplateListCubit>().saveTemplate(updated);
    if (!context.mounted) {
      return;
    }
    if (r.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r.failureOrNull!.messageAr)),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    MessageTemplate t,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: QaydText(
          AppStringsAr.templateDeleteTitle,
          slot: QaydTextStyleSlot.titleLarge,
        ),
        content: QaydText(
          AppStringsAr.templateDeleteMessage,
          slot: QaydTextStyleSlot.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStringsAr.templateEditCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppStringsAr.templateDeleteConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) {
      return;
    }
    final r = await context.read<TemplateListCubit>().deleteTemplate(t.id);
    if (!context.mounted) {
      return;
    }
    if (r.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r.failureOrNull!.messageAr)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;

    return Scaffold(
      appBar: AppBar(
        title: QaydText(
          AppStringsAr.notificationTemplatesTitle,
          slot: QaydTextStyleSlot.titleLarge,
        ),
        actions: const [
          SettingsAppBarAction(),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [
                  gold.withValues(alpha: 0.85),
                  gold.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: BlocBuilder<TemplateListCubit, TemplateListState>(
        builder: (context, state) {
          return switch (state) {
            TemplateListLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            TemplateListFailure(:final failure) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(SpacingTokens.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QaydText(
                        failure.messageAr,
                        slot: QaydTextStyleSlot.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: SpacingTokens.md),
                      FilledButton.tonal(
                        onPressed: () =>
                            context.read<TemplateListCubit>().load(),
                        child: Text(AppStringsAr.retryAction),
                      ),
                    ],
                  ),
                ),
              ),
            TemplateListReady(:final templates) => templates.isEmpty
                ? Center(
                    child: QaydText(
                      AppStringsAr.notificationNoTemplates,
                      slot: QaydTextStyleSlot.bodyLarge,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      SpacingTokens.md,
                      SpacingTokens.sm,
                      SpacingTokens.md,
                      SpacingTokens.xxl,
                    ),
                    itemCount: templates.length,
                    itemBuilder: (context, i) {
                      final t = templates[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
                        child: Card(
                          child: ListTile(
                            title: QaydText(
                              t.name,
                              slot: QaydTextStyleSlot.titleSmall,
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: SpacingTokens.xs),
                              child: QaydText(
                                _kindLabel(t.kind),
                                slot: QaydTextStyleSlot.bodySmall,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!t.isSystem)
                                  IconButton(
                                    tooltip: AppStringsAr.templateDeleteTitle,
                                    icon: const Icon(Icons.delete_outline_rounded),
                                    onPressed: () =>
                                        _confirmDelete(context, t),
                                  ),
                                IconButton(
                                  tooltip: AppStringsAr.templateEditTitle,
                                  icon: Icon(Icons.edit_rounded, color: gold),
                                  onPressed: () => _edit(context, t),
                                ),
                              ],
                            ),
                            onTap: () => _edit(context, t),
                          ),
                        ),
                      );
                    },
                  ),
          };
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_template_list',
        onPressed: () => _openCreate(context),
        backgroundColor: gold,
        foregroundColor: ColorTokens.navy950,
        icon: const Icon(Icons.add_rounded),
        label: Text(AppStringsAr.templateAddFab),
      ),
    );
  }
}
