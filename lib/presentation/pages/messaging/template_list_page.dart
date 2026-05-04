import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/entities/message_template.dart';
import 'package:qayd/domain/value_objects/message_template_kind.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/pages/messaging/template_list_cubit.dart';
import 'package:qayd/presentation/pages/messaging/template_list_state.dart';
import 'package:qayd/presentation/components/inputs/qayd_text_field.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/pages/messaging/template_text_controller.dart';

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
    final bodyCtrl = TemplateTextController(
        initialDbText:
            AppStrings.dearCustomernweWouldLike2);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: QaydText(
              AppStrings.templateAddTitle,
              slot: QaydTextStyleSlot.titleLarge,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<MessageTemplateKind>(
                    initialValue: kind,
                    decoration: InputDecoration(
                      labelText: AppStrings.templateKindPickerLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: MessageTemplateKind.receipt,
                        child: Text(AppStrings.templateKindReceipt),
                      ),
                      DropdownMenuItem(
                        value: MessageTemplateKind.payment,
                        child: Text(AppStrings.templateKindPayment),
                      ),
                      DropdownMenuItem(
                        value: MessageTemplateKind.accountBalance,
                        child: Text(AppStrings.templateKindAccount),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => kind = v);
                      }
                    },
                  ),
                  SizedBox(height: SpacingTokens.md),
                  QaydTextField(
                    controller: nameCtrl,
                    label: AppStrings.templateNameLabel,
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(height: SpacingTokens.md),
                  QaydTextField(
                    controller: bodyCtrl,
                    label: AppStrings.templateBodyLabel,
                    maxLines: 6,
                    textInputAction: TextInputAction.done,
                  ),
                  SizedBox(height: SpacingTokens.sm),
                  _buildVariableChipsRow(kind, bodyCtrl),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  FocusScope.of(ctx).unfocus();
                  Navigator.of(ctx).pop(false);
                },
                child: Text(AppStrings.templateEditCancel),
              ),
              FilledButton(
                onPressed: () {
                  FocusScope.of(ctx).unfocus();
                  Navigator.of(ctx).pop(true);
                },
                child: Text(AppStrings.templateEditSave),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true || !context.mounted) {
      Future.delayed(const Duration(milliseconds: 250), () {
        nameCtrl.dispose();
        bodyCtrl.dispose();
      });
      return;
    }
    final name = nameCtrl.text.trim();
    final bodyText = bodyCtrl.dbText;
    Future.delayed(const Duration(milliseconds: 250), () {
      nameCtrl.dispose();
      bodyCtrl.dispose();
    });
    final r = await InjectionContainer.createMessageTemplateUseCase(
      kind: kind,
      name: name,
      body: bodyText,
    );
    if (!context.mounted) {
      return;
    }
    if (r.isFailure) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(r.failureOrNull!.messageAr)));
      return;
    }
    await context.read<TemplateListCubit>().load();
  }

  String _kindLabel(MessageTemplateKind k) {
    return switch (k) {
      MessageTemplateKind.receipt => AppStrings.templateKindReceipt,
      MessageTemplateKind.payment => AppStrings.templateKindPayment,
      MessageTemplateKind.accountBalance => AppStrings.templateKindAccount,
    };
  }

  Future<void> _edit(BuildContext context, MessageTemplate t) async {
    final nameCtrl = TextEditingController(text: t.name);
    final bodyCtrl = TemplateTextController(initialDbText: t.body);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: QaydText(
          AppStrings.templateEditTitle,
          slot: QaydTextStyleSlot.titleLarge,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              QaydTextField(
                controller: nameCtrl,
                label: AppStrings.templateNameLabel,
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: SpacingTokens.md),
              QaydTextField(
                controller: bodyCtrl,
                label: AppStrings.templateBodyLabel,
                maxLines: 8,
                textInputAction: TextInputAction.done,
              ),
              SizedBox(height: SpacingTokens.sm),
              _buildVariableChipsRow(t.kind, bodyCtrl),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              FocusScope.of(ctx).unfocus();
              Navigator.of(ctx).pop(false);
            },
            child: Text(AppStrings.templateEditCancel),
          ),
          FilledButton(
            onPressed: () {
              FocusScope.of(ctx).unfocus();
              Navigator.of(ctx).pop(true);
            },
            child: Text(AppStrings.templateEditSave),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) {
      Future.delayed(const Duration(milliseconds: 250), () {
        nameCtrl.dispose();
        bodyCtrl.dispose();
      });
      return;
    }
    final updated = MessageTemplate(
      id: t.id,
      kind: t.kind,
      name: nameCtrl.text.trim(),
      body: bodyCtrl.dbText,
      isSystem: t.isSystem,
      sortOrder: t.sortOrder,
      createdAt: t.createdAt,
      updatedAt: DateTime.now(),
    );
    Future.delayed(const Duration(milliseconds: 250), () {
      nameCtrl.dispose();
      bodyCtrl.dispose();
    });
    final r = await context.read<TemplateListCubit>().saveTemplate(updated);
    if (!context.mounted) {
      return;
    }
    if (r.isFailure) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(r.failureOrNull!.messageAr)));
    }
  }

  Future<void> _confirmDelete(BuildContext context, MessageTemplate t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: QaydText(
          AppStrings.templateDeleteTitle,
          slot: QaydTextStyleSlot.titleLarge,
        ),
        content: QaydText(
          AppStrings.templateDeleteMessage,
          slot: QaydTextStyleSlot.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.templateEditCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppStrings.templateDeleteConfirm),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(r.failureOrNull!.messageAr)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;

    return Scaffold(
      appBar: QaydAppBar(
        title: AppStrings.notificationTemplatesTitle,
        actions: [
          IconButton(
            tooltip: AppStrings.retryAction,
            onPressed: () => context.read<TemplateListCubit>().load(),
            icon: Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: BlocBuilder<TemplateListCubit, TemplateListState>(
        builder: (context, state) {
          return switch (state) {
            TemplateListLoading() => Center(
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
                      SizedBox(height: SpacingTokens.md),
                      FilledButton.tonal(
                        onPressed: () =>
                            context.read<TemplateListCubit>().load(),
                        child: Text(AppStrings.retryAction),
                      ),
                    ],
                  ),
                ),
              ),
            TemplateListReady(:final templates) => templates.isEmpty
                ? Center(
                    child: QaydText(
                      AppStrings.notificationNoTemplates,
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
                        padding: const EdgeInsets.only(
                          bottom: SpacingTokens.sm,
                        ),
                        child: Card(
                          child: ListTile(
                            title: QaydText(
                              t.name,
                              slot: QaydTextStyleSlot.titleSmall,
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(
                                top: SpacingTokens.xs,
                              ),
                              child: QaydText(
                                _kindLabel(t.kind),
                                slot: QaydTextStyleSlot.bodySmall,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!t.isSystem)
                                  IconButton(
                                    tooltip: AppStrings.templateDeleteTitle,
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                    ),
                                    onPressed: () => _confirmDelete(context, t),
                                  ),
                                IconButton(
                                  tooltip: AppStrings.templateEditTitle,
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
        icon: Icon(Icons.add_rounded),
        label: Text(AppStrings.templateAddFab),
      ),
    );
  }

  Widget _buildVariableChipsRow(
      MessageTemplateKind currentKind, TemplateTextController controller) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: kTemplateVariables.where((v) {
          if (v.kindRestricted != null && v.kindRestricted != currentKind) {
            return false;
          }
          return true;
        }).map((v) {
          return Padding(
            padding: const EdgeInsets.only(left: SpacingTokens.xs),
            child: ActionChip(
              label: Text(v.label, style:  TextStyle(fontSize: 12)),
              backgroundColor: Colors.amber.withOpacity(0.1),
              side: BorderSide(color: Colors.amber.shade300),
              labelStyle: TextStyle(color: Colors.amber.shade900),
              onPressed: () {
                controller.insertVariable(v);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
