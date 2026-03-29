import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/pages/messaging/notification_preview_cubit.dart';
import 'package:qayd/presentation/pages/messaging/notification_preview_mode.dart';
import 'package:qayd/presentation/pages/messaging/notification_preview_state.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

class NotificationPreviewPage extends StatelessWidget {
  const NotificationPreviewPage({super.key, required this.mode});

  final NotificationPreviewMode mode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationPreviewCubit(
        mode: mode,
        templateRepository: InjectionContainer.messageTemplateRepository,
        getVoucherDetails: InjectionContainer.getVoucherDetailsUseCase,
        getAccountDetails: InjectionContainer.getAccountDetailsUseCase,
        logIntent: InjectionContainer.logNotificationIntentUseCase,
      )..load(),
      child: const _NotificationPreviewView(),
    );
  }
}

class _NotificationPreviewView extends StatefulWidget {
  const _NotificationPreviewView();

  @override
  State<_NotificationPreviewView> createState() =>
      _NotificationPreviewViewState();
}

class _NotificationPreviewViewState extends State<_NotificationPreviewView> {
  late final TextEditingController _bodyController;

  @override
  void initState() {
    super.initState();
    _bodyController = TextEditingController();
  }

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;

    return Scaffold(
      appBar: AppBar(
        title: QaydText(
          AppStringsAr.notificationPreviewTitle,
          slot: QaydTextStyleSlot.titleLarge,
        ),
      ),
      body: BlocConsumer<NotificationPreviewCubit, NotificationPreviewState>(
        listenWhen: (p, c) {
          if (c is! NotificationPreviewReady) {
            return false;
          }
          if (p is! NotificationPreviewReady) {
            return true;
          }
          return p.bodyText != c.bodyText ||
              p.selectedTemplateId != c.selectedTemplateId;
        },
        listener: (context, state) {
          if (state is NotificationPreviewReady) {
            if (_bodyController.text != state.bodyText) {
              _bodyController.text = state.bodyText;
            }
          }
        },
        builder: (context, state) {
          return switch (state) {
            NotificationPreviewLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            NotificationPreviewFailure(:final failure) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(SpacingTokens.lg),
                  child: QaydText(
                    failure.messageAr,
                    slot: QaydTextStyleSlot.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            NotificationPreviewReady(
              :final templates,
              :final selectedTemplateId,
            ) =>
              templates.isEmpty
                  ? Center(
                      child: QaydText(
                        AppStringsAr.notificationNoTemplates,
                        slot: QaydTextStyleSlot.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(SpacingTokens.lg),
                      children: [
                        QaydText(
                          AppStringsAr.notificationSelectTemplate,
                          slot: QaydTextStyleSlot.labelLarge,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: SpacingTokens.sm),
                        DropdownButtonFormField<String>(
                          value: selectedTemplateId,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                          ),
                          items: templates
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t.id,
                                  child: Text(t.name),
                                ),
                              )
                              .toList(),
                          onChanged: (id) {
                            if (id != null) {
                              context
                                  .read<NotificationPreviewCubit>()
                                  .selectTemplate(id);
                            }
                          },
                        ),
                        const SizedBox(height: SpacingTokens.lg),
                        QaydText(
                          AppStringsAr.notificationMessageBody,
                          slot: QaydTextStyleSlot.labelLarge,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: SpacingTokens.sm),
                        TextField(
                          controller: _bodyController,
                          maxLines: 12,
                          minLines: 8,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignLabelWithHint: true,
                            filled: true,
                          ),
                          onChanged: (t) => context
                              .read<NotificationPreviewCubit>()
                              .setBodyText(t),
                        ),
                        const SizedBox(height: SpacingTokens.xl),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final r = await context
                                      .read<NotificationPreviewCubit>()
                                      .sendSms();
                                  if (!context.mounted) {
                                    return;
                                  }
                                  if (r.isFailure) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(r.failureOrNull!.messageAr),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppStringsAr.notificationIntentSms,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.sms_outlined),
                                label: Text(AppStringsAr.notificationSendSms),
                              ),
                            ),
                            const SizedBox(width: SpacingTokens.md),
                            Expanded(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: gold,
                                  foregroundColor: ColorTokens.navy950,
                                ),
                                onPressed: () async {
                                  final r = await context
                                      .read<NotificationPreviewCubit>()
                                      .sendWhatsApp();
                                  if (!context.mounted) {
                                    return;
                                  }
                                  if (r.isFailure) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(r.failureOrNull!.messageAr),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppStringsAr.notificationIntentWa,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.chat_rounded),
                                label: Text(AppStringsAr.notificationSendWhatsApp),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
          };
        },
      ),
    );
  }
}
