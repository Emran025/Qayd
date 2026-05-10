import 'dart:convert';
import 'dart:io';

import 'package:qayd/application/accounts/dtos/account_summary_dto.dart';
import 'package:qayd/application/accounts/dtos/list_accounts_output.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:qayd/application/import_export/legacy_migration_use_case.dart';
import 'package:qayd/application/accounts/dtos/list_accounts_input.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/value_objects/standard_account_classification_kind.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/widgets/account_picker_sheet.dart';
import 'package:qayd/presentation/widgets/qayd_scaffold.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';

// ─── Wizard phases ────────────────────────────────────────────────────────────

enum _Phase { pickFile, analyzing, resolving, importing, done }

// ─── Page ─────────────────────────────────────────────────────────────────────

class ImportWizardPage extends StatefulWidget {
  const ImportWizardPage({super.key});

  @override
  State<ImportWizardPage> createState() => _ImportWizardPageState();
}

class _ImportWizardPageState extends State<ImportWizardPage> {
  _Phase _phase = _Phase.pickFile;

  MigrationAnalysisResult? _analysis;
  ImportSummary? _summary;
  String? _errorMessage;
  double? _importProgress;

  /// User decisions: legacyId → AccountResolution
  final Map<String, AccountResolution> _resolutions = {};

  List<AccountSummaryDto> _rootAccounts = [];

  // ── File Picking ─────────────────────────────────────────────────────────────

  Future<void> _pickAndAnalyse() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final bytes = result.files.first.bytes;
    final path = result.files.first.path;
    String? content;

    if (bytes != null) {
      content = utf8.decode(bytes);
    } else if (path != null) {
      content = await File(path).readAsString();
    }

    if (content == null) {
      _showError(AppStrings.theFileCouldNot1);
      return;
    }

    // ── Justification & Permission ───────────────────────────────────────────
    final hasPermission = await _ensureContactsPermission();
    if (!hasPermission) {
      // We still proceed, but phone matching will be disabled.
      // Or we can stop here. The user said it's "necessary".
      // But they also said "if we don't find a match, we'll put it as is".
      // So we can proceed.
    }

    setState(() {
      _phase = _Phase.analyzing;
      _errorMessage = null;
    });

    final analysisResult =
        await InjectionContainer.legacyMigrationUseCase.analyzeBundle(content);

    if (!mounted) return;

    if (analysisResult is FailureResult) {
      setState(() {
        _errorMessage = (analysisResult as FailureResult).failure.messageAr;
        _phase = _Phase.pickFile;
      });
      return;
    }

    final analysis = (analysisResult as Success<MigrationAnalysisResult>).value;

    // Pre-fill default resolutions: exact matches → merge, others → createNew
    _resolutions.clear();
    for (final c in analysis.accountConflicts) {
      if (c.type == AccountConflictType.exactMatch &&
          c.existingAccount != null) {
        _resolutions[c.legacyIdStr] =
            AccountResolution.merge(c.existingAccount!.id.value);
      } else {
        _resolutions[c.legacyIdStr] = const AccountResolution.createNew();
      }
    }

    final rootsResult =
        await InjectionContainer.listAccountsUseCase(const ListAccountsInput());
    if (rootsResult is Success<ListAccountsOutput>) {
      _rootAccounts =
          rootsResult.value.accounts.where((a) => a.isRoot).toList();
    }

    setState(() {
      _analysis = analysis;
      _phase = _Phase.resolving;
    });
  }

  // ── Import Execution ─────────────────────────────────────────────────────────

  Future<void> _startImport() async {
    final analysis = _analysis!;

    setState(() {
      _phase = _Phase.importing;
      _importProgress = 0.0;
    });

    // Phase 2a: Resolve accounts (create new / assign merges)
    final resolveResult =
        await InjectionContainer.legacyMigrationUseCase.resolveAccounts(
      analysis: analysis,
      userResolutions: Map.from(_resolutions),
    );
    if (!mounted) return;

    if (resolveResult is FailureResult) {
      setState(() {
        _errorMessage = (resolveResult as FailureResult).failure.messageAr;
        _phase = _Phase.resolving;
      });
      return;
    }

    final finalResolutions =
        (resolveResult as Success<Map<String, String>>).value;

    // Phase 2b: Import transactions
    final importResult =
        await InjectionContainer.legacyMigrationUseCase.executeImport(
      bundle: analysis.rawBundle,
      accountResolutions: finalResolutions,
      onProgress: (current, total) {
        if (!mounted) return;
        setState(() {
          _importProgress = total > 0 ? current / total : null;
        });
      },
    );
    if (!mounted) return;

    if (importResult is FailureResult) {
      setState(() {
        _errorMessage = (importResult as FailureResult).failure.messageAr;
        _phase = _Phase.resolving;
      });
      return;
    }

    setState(() {
      _summary = (importResult as Success<ImportSummary>).value;
      _phase = _Phase.done;
    });
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _reset() {
    setState(() {
      _phase = _Phase.pickFile;
      _analysis = null;
      _summary = null;
      _errorMessage = null;
      _importProgress = null;
      _resolutions.clear();
    });
  }

  Future<bool> _ensureContactsPermission() async {
    final status =
        await InjectionContainer.deviceContactsService.requestPermission();
    if (status) return true;

    if (!mounted) return false;

    // Show justification dialog if not granted yet
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppStrings.accessToContacts,
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          AppStrings.autostring5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.skip),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: ColorTokens.emerald600,
            ),
            child: Text(AppStrings.allowAccess),
          ),
        ],
      ),
    );

    if (result == true) {
      return await InjectionContainer.deviceContactsService.requestPermission();
    }
    return false;
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return QaydScaffold(
      appBar: QaydAppBar(
        title: AppStrings.importData,
        actions: _phase == _Phase.resolving
            ? [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.sm, vertical: 8),
                  child: FilledButton(
                    onPressed: _startImport,
                    style: FilledButton.styleFrom(
                      backgroundColor: ColorTokens.emerald600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: SpacingTokens.md),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(RadiusTokens.md),
                      ),
                    ),
                    child: Text(
                      AppStrings.startImport,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: switch (_phase) {
          _Phase.pickFile => _PickFilePage(
              key: const ValueKey('pick'),
              onPick: _pickAndAnalyse,
              errorMessage: _errorMessage,
            ),
          _Phase.analyzing =>  _LoadingPage(
              key: ValueKey('analyzing'),
              message: AppStrings.parsingThePackage,
            ),
          _Phase.resolving => _ResolvingPage(
              key: const ValueKey('resolving'),
              analysis: _analysis!,
              resolutions: _resolutions,
              rootAccounts: _rootAccounts,
              onResolutionChanged: (id, r) =>
                  setState(() => _resolutions[id] = r),
              onConfirm: _startImport,
            ),
          _Phase.importing => _LoadingPage(
              key: const ValueKey('importing'),
              message: AppStrings.importingData,
              progress: _importProgress,
            ),
          _Phase.done => _DonePage(
              key: const ValueKey('done'),
              summary: _summary!,
              onReset: _reset,
            ),
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Phase 1 — Pick File
// ══════════════════════════════════════════════════════════════════════════════

class _PickFilePage extends StatelessWidget {
  const _PickFilePage({
    super.key,
    required this.onPick,
    this.errorMessage,
  });

  final VoidCallback onPick;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header card ──────────────────────────────────────────────────
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.upload_file_rounded,
                        color: scheme.onPrimaryContainer,
                        size: 26,
                      ),
                    ),
                    SizedBox(width: SpacingTokens.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.importModuleFromOld,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 2),
                          Text(
                            AppStrings.importAccountsAndFinancial,
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SpacingTokens.lg),

                // Pick button
                InkWell(
                  onTap: onPick,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: SpacingTokens.xl,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.4),
                        width: 1.5,
                        strokeAlign: BorderSide.strokeAlignCenter,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      color: scheme.primaryContainer.withValues(alpha: 0.25),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.folder_open_rounded,
                          size: 44,
                          color: scheme.primary,
                        ),
                        SizedBox(height: SpacingTokens.sm),
                        Text(
                          AppStrings.choosePackageFileJson,
                          style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'qayd_bundle_v2_*.json',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (errorMessage != null) ...[
                  SizedBox(height: SpacingTokens.md),
                  _WarningBanner(message: errorMessage!),
                ],
              ],
            ),
          ),

          SizedBox(height: SpacingTokens.md),

          // ── How it works ──────────────────────────────────────────────────
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.howDoesImportWork,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: SpacingTokens.md),
                _StepHint(
                  number: AppStrings.s1,
                  title: AppStrings.accountAnalysis,
                  subtitle: AppStrings.identifyAndMatchDuplicate,
                ),
                _StepHint(
                  number: AppStrings.s2,
                  title: AppStrings.resolvingConflicts,
                  subtitle: AppStrings.forEachAccountMerge,
                ),
                _StepHint(
                  number: AppStrings.s3,
                  title: AppStrings.importBonds,
                  subtitle: AppStrings.transactionVouchersAreCreated,
                ),
                _StepHint(
                  number: AppStrings.s4,
                  title: AppStrings.reviewAndConfirm,
                  subtitle: AppStrings.bondsAreApprovedFrom,
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Phase 2 — Loading
// ══════════════════════════════════════════════════════════════════════════════

class _LoadingPage extends StatelessWidget {
  const _LoadingPage({super.key, required this.message, this.progress});

  final String message;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (progress == null)
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: scheme.primary,
                ),
              )
            else
              Column(
                children: [
                  Text(
                    '${(progress! * 100).toInt()}%',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  SizedBox(height: SpacingTokens.md),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      color: scheme.primary,
                      backgroundColor: scheme.primary.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            SizedBox(height: SpacingTokens.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Phase 3 — Conflict Resolution
// ══════════════════════════════════════════════════════════════════════════════
class _ResolvingPage extends StatefulWidget {
  final MigrationAnalysisResult analysis;
  final Map<String, AccountResolution> resolutions;
  final List<AccountSummaryDto> rootAccounts;
  final void Function(String legacyId, AccountResolution r) onResolutionChanged;
  final VoidCallback onConfirm;

  const _ResolvingPage({
    super.key,
    required this.analysis,
    required this.resolutions,
    required this.rootAccounts,
    required this.onResolutionChanged,
    required this.onConfirm,
  });

  @override
  State<_ResolvingPage> createState() => _ResolvingPageState();
}

enum _Filter { all, exact, partial, newAccounts, vouchers }

class _ResolvingPageState extends State<_ResolvingPage> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final conflicts = widget.analysis.accountConflicts;
    final filteredConflicts = conflicts.where((c) {
      if (_filter == _Filter.all) return true;
      if (_filter == _Filter.exact) {
        return c.type == AccountConflictType.exactMatch;
      }
      if (_filter == _Filter.partial) {
        return c.type == AccountConflictType.partialMatch;
      }
      if (_filter == _Filter.newAccounts) {
        return c.type == AccountConflictType.noMatch;
      }
      return false;
    }).toList();

    final transactions =
        (widget.analysis.rawBundle['transactions'] as List? ?? [])
            .cast<Map<String, dynamic>>();

    final exactCount = widget.analysis.exactMatchCount;
    final partialCount = widget.analysis.partialMatchCount;
    final newCount = widget.analysis.newAccountCount;
    final txCount =
        (widget.analysis.rawBundle['stats']?['transactions_count'] as num? ?? 0)
            .toInt();
    final scheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        // ── Stats banner ─────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              SpacingTokens.md,
              SpacingTokens.md,
              SpacingTokens.md,
              0,
            ),
            child: Row(
              children: [
                _MiniStat(
                  label: AppStrings.accounts,
                  value: '${conflicts.length}',
                  color: scheme.primary,
                  isSelected: _filter == _Filter.all,
                  onTap: () => setState(() => _filter = _Filter.all),
                ),
                SizedBox(width: SpacingTokens.sm),
                _MiniStat(
                  label: AppStrings.movements,
                  value: '$txCount',
                  color: ColorTokens.emerald600,
                  isSelected: _filter == _Filter.vouchers,
                  onTap: () => setState(() => _filter = _Filter.vouchers),
                ),
                SizedBox(width: SpacingTokens.sm),
                _MiniStat(
                  label: AppStrings.perfectMatch,
                  value: '$exactCount',
                  color: ColorTokens.emerald700,
                  isSelected: _filter == _Filter.exact,
                  onTap: () => setState(() => _filter = _Filter.exact),
                ),
                SizedBox(width: SpacingTokens.sm),
                _MiniStat(
                  label: AppStrings.partial,
                  value: '$partialCount',
                  color: ColorTokens.warningAmber,
                  isSelected: _filter == _Filter.partial,
                  onTap: () => setState(() => _filter = _Filter.partial),
                ),
                SizedBox(width: SpacingTokens.sm),
                _MiniStat(
                  label: AppStrings.newStr,
                  value: '$newCount',
                  color: ColorTokens.debitBlue,
                  isSelected: _filter == _Filter.newAccounts,
                  onTap: () => setState(() => _filter = _Filter.newAccounts),
                ),
              ],
            ),
          ),
        ),

        // ── Instructions ─────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              SpacingTokens.md,
              SpacingTokens.md,
              SpacingTokens.md,
              0,
            ),
            child: Text(
              _filter == _Filter.vouchers
                  ? AppStrings.listOfBondsTo
                  : AppStrings.reviewEachAccountAnd,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
        ),

        // ── Main list ────────────────────────────────────────────────────────
        if (_filter == _Filter.vouchers)
          SliverList.builder(
            itemCount: transactions.length,
            itemBuilder: (context, i) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  SpacingTokens.md,
                  SpacingTokens.sm,
                  SpacingTokens.md,
                  0,
                ),
                child: _TransactionCard(tx: transactions[i]),
              );
            },
          )
        else
          SliverList.builder(
            itemCount: filteredConflicts.length,
            itemBuilder: (context, i) {
              final conflict = filteredConflicts[i];
              final resolution = widget.resolutions[conflict.legacyIdStr] ??
                  const AccountResolution.createNew();
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  SpacingTokens.md,
                  SpacingTokens.sm,
                  SpacingTokens.md,
                  i == filteredConflicts.length - 1 ? SpacingTokens.xl : 0,
                ),
                child: _ConflictCard(
                  conflict: conflict,
                  resolution: resolution,
                  rootAccounts: widget.rootAccounts,
                  onResolutionChanged: (r) =>
                      widget.onResolutionChanged(conflict.legacyIdStr, r),
                ),
              );
            },
          ),

        // ── Confirm button ────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              SpacingTokens.md,
              SpacingTokens.xl,
              SpacingTokens.md,
              SpacingTokens.xl,
            ),
            child: FilledButton.icon(
              onPressed: widget.onConfirm,
              icon: Icon(Icons.download_done_rounded, size: 20),
              label: Text(AppStrings.startImport),
              style: FilledButton.styleFrom(
                backgroundColor: ColorTokens.emerald600,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Conflict Card ─────────────────────────────────────────────────────────────

class _ConflictCard extends StatelessWidget {
  const _ConflictCard({
    required this.conflict,
    required this.resolution,
    required this.rootAccounts,
    required this.onResolutionChanged,
  });

  final AccountMigrationConflict conflict;
  final AccountResolution resolution;
  final List<AccountSummaryDto> rootAccounts;
  final ValueChanged<AccountResolution> onResolutionChanged;

  Color _conflictColor(BuildContext context) => switch (conflict.type) {
        AccountConflictType.exactMatch => ColorTokens.emerald700,
        AccountConflictType.partialMatch => ColorTokens.warningAmber,
        AccountConflictType.noMatch => ColorTokens.debitBlue,
      };

  String _conflictLabel() => switch (conflict.type) {
        AccountConflictType.exactMatch => AppStrings.perfectMatch,
        AccountConflictType.partialMatch => AppStrings.partialMatch,
        AccountConflictType.noMatch => AppStrings.newAccount,
      };

  IconData _conflictIcon() => switch (conflict.type) {
        AccountConflictType.exactMatch => Icons.check_circle_outline_rounded,
        AccountConflictType.partialMatch => Icons.warning_amber_rounded,
        AccountConflictType.noMatch => Icons.add_circle_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _conflictColor(context);
    final mergeTargetName = conflict.existingAccount?.name;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Account header ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(SpacingTokens.md),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: accent.withValues(alpha: 0.15),
                  child: Text(
                    conflict.name.isNotEmpty
                        ? conflict.name.characters.first
                        : AppStrings.str1,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(width: SpacingTokens.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conflict.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (conflict.phone.isNotEmpty)
                        Text(
                          conflict.phone,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      if (conflict.groupName.isNotEmpty)
                        Text(
                          conflict.groupName,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),

                // Conflict type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: accent.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_conflictIcon(), color: accent, size: 14),
                      SizedBox(width: 4),
                      Text(
                        _conflictLabel(),
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Legacy balance chips ──────────────────────────────────────────
          if (conflict.legacyBalances.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                left: SpacingTokens.md,
                right: SpacingTokens.md,
                bottom: SpacingTokens.sm,
              ),
              child: Wrap(
                spacing: 6,
                children: [
                  for (final b in conflict.legacyBalances)
                    _BalanceChip(
                      amount: (b['balance'] as num? ?? 0).toDouble(),
                      code: b['currency_code']?.toString() ?? '',
                    ),
                ],
              ),
            ),

          const Divider(height: 1),

          // ── Existing account match banner ────────────────────────────────
          if (mergeTargetName != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SpacingTokens.md,
                SpacingTokens.sm,
                SpacingTokens.md,
                0,
              ),
              child: Container(
                padding: const EdgeInsets.all(SpacingTokens.sm),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: scheme.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link_rounded, size: 16, color: scheme.primary),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        AppStrings.matchedInQayd(mergeTargetName),

                        style: TextStyle(
                          color: scheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Resolution actions ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(SpacingTokens.md),
            child: Row(
              children: [
                // Merge
                _ActionChip(
                  label: AppStrings.toMerge,
                  icon: Icons.merge_rounded,
                  isSelected: resolution.action == ResolutionAction.merge,
                  color: ColorTokens.emerald600,
                  onTap: () async {
                    final picked = await showAccountPickerSheet(
                      context,
                      listAccounts: InjectionContainer.listAccountsUseCase,
                      hideSterileRoots: true,
                      rootAllowed: false,
                      initialSearchQuery: conflict.phone.isNotEmpty
                          ? conflict.phone
                          : conflict.name,
                    );
                    if (picked == null) return;
                    onResolutionChanged(AccountResolution.merge(picked.id));
                  },
                ),
                SizedBox(width: SpacingTokens.sm),

                // Create New
                _ActionChip(
                  label: AppStrings.createNew,
                  icon: Icons.person_add_rounded,
                  isSelected: resolution.action == ResolutionAction.createNew,
                  color: ColorTokens.debitBlue,
                  onTap: () =>
                      onResolutionChanged(const AccountResolution.createNew()),
                ),
                SizedBox(width: SpacingTokens.sm),

                // Skip
                _ActionChip(
                  label: AppStrings.skip,
                  icon: Icons.skip_next_rounded,
                  isSelected: resolution.action == ResolutionAction.skip,
                  color: scheme.outline,
                  onTap: () =>
                      onResolutionChanged(const AccountResolution.skip()),
                ),
              ],
            ),
          ),
          if (resolution.action == ResolutionAction.createNew) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(SpacingTokens.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.linkToRootAccount,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: SpacingTokens.sm),
                  SizedBox(
                    width: double.infinity,
                    child: DropdownButtonFormField<String>(
                      initialValue: resolution.forcedParentId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: scheme.surfaceContainerHigh,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: scheme.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: scheme.outlineVariant),
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurface,
                        fontFamily: 'Cairo',
                      ),
                      hint: Text(
                        _getDefaultParentName(conflict, rootAccounts),
                        style: TextStyle(color: scheme.primary),
                      ),
                      items: rootAccounts.map((root) {
                        return DropdownMenuItem<String>(
                          value: root.id,
                          child: Text(root.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          onResolutionChanged(
                            AccountResolution.createNew(forcedParentId: val),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _getDefaultParentName(
  AccountMigrationConflict conflict,
  List<AccountSummaryDto> roots,
) {
  final legacyClassification =
      conflict.legacyData['classification']?.toString() ?? '';
  final isPayable = legacyClassification == 'payables';
  final kindName = isPayable
      ? StandardAccountClassificationKind.payables.name
      : StandardAccountClassificationKind.receivables.name;

  final defaultRoot =
      roots.where((a) => a.standardClassificationKind == kindName).firstOrNull;

  return defaultRoot?.name ??
      (isPayable
          ? AppStrings.obligationsAndDebts
          : AppStrings.rightsAndEntitlements);
}

// ══════════════════════════════════════════════════════════════════════════════
// Phase 5 — Done
// ══════════════════════════════════════════════════════════════════════════════

class _DonePage extends StatelessWidget {
  const _DonePage({
    super.key,
    required this.summary,
    required this.onReset,
  });

  final ImportSummary summary;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Success illustration
          Container(
            padding: const EdgeInsets.all(SpacingTokens.xl),
            decoration: BoxDecoration(
              color: ColorTokens.emerald700.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: ColorTokens.emerald700.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 72,
                  color: ColorTokens.emerald600,
                ),
                SizedBox(height: SpacingTokens.md),
                Text(
                  AppStrings.importCompleted,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: ColorTokens.emerald700,
                      ),
                ),
                SizedBox(height: 4),
                Text(
                  AppStrings.bondsCreatedInPending,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: SpacingTokens.lg),

          // Stats
          _SectionCard(
            child: Column(
              children: [
                _SummaryRow(
                  icon: Icons.receipt_long_rounded,
                  label: AppStrings.importedBonds,
                  value: '${summary.imported}',
                  color: ColorTokens.emerald600,
                ),
                const Divider(height: SpacingTokens.lg),
                _SummaryRow(
                  icon: Icons.compare_arrows_rounded,
                  label: AppStrings.includingTransfers,
                  value: '${summary.transfers}',
                  color: scheme.primary,
                ),
                const Divider(height: SpacingTokens.lg),
                _SummaryRow(
                  icon: Icons.skip_next_rounded,
                  label: AppStrings.skippedMovements,
                  value: '${summary.skipped}',
                  color: scheme.outline,
                ),
              ],
            ),
          ),

          SizedBox(height: SpacingTokens.md),

          // Next steps
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.nextSteps,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: SpacingTokens.md),
                _StepHint(
                  number: AppStrings.s1,
                  title: AppStrings.reviewOutstandingBonds,
                  subtitle: AppStrings.searchBondsForStatus(AppStrings.waiting),

                ),
                _StepHint(
                  number: AppStrings.s2,
                  title: AppStrings.bondApproval,
                  subtitle: AppStrings.openEachDocumentVerify,
                  isLast: true,
                ),
              ],
            ),
          ),

          SizedBox(height: SpacingTokens.lg),

          // Import another
          OutlinedButton.icon(
            onPressed: onReset,
            icon: Icon(Icons.upload_file_rounded, size: 18),
            label: Text(AppStrings.importAnotherFile),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Shared helper widgets ─────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: child,
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: scheme.onErrorContainer, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepHint extends StatelessWidget {
  const _StepHint({
    required this.number,
    required this.title,
    required this.subtitle,
    this.isLast = false,
  });

  final String number;
  final String title;
  final String subtitle;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: scheme.primaryContainer,
                child: Text(
                  number,
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: scheme.outlineVariant,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : SpacingTokens.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    this.isSelected = false,
    this.onTap,
  });

  final String label;
  final String value;
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.2),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.9)
                      : color.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.12)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : scheme.outlineVariant,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? color : scheme.outline),
              SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.tx});
  final Map<String, dynamic> tx;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final type = tx['type']?.toString() ?? 'receipt';
    final isReceipt = type == 'receipt';
    final color = isReceipt ? ColorTokens.creditGreen : ColorTokens.errorSoft;
    final amount = (tx['amount_raw'] as num? ?? 0).toDouble();
    final currency = tx['currency_code']?.toString() ?? 'YER';
    final date = tx['date']?.toString() ?? '';
    final description =
        tx['description']?.toString() ?? AppStrings.withoutDescription;
    final counterparty =
        tx['counterparty_name']?.toString() ?? AppStrings.anonymousParty;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isReceipt ? AppStrings.catchStr : AppStrings.exchange,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                date,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          SizedBox(height: SpacingTokens.sm),
          Text(
            counterparty,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
          SizedBox(height: SpacingTokens.sm),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              '${amount.toStringAsFixed(2)} $currency',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceChip extends StatelessWidget {
  const _BalanceChip({required this.amount, required this.code});
  final double amount;
  final String code;

  @override
  Widget build(BuildContext context) {
    final isPos = amount >= 0;
    final color = isPos ? ColorTokens.creditGreen : ColorTokens.errorSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        '${isPos ? '+' : ''}${amount.toStringAsFixed(2)} $code',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        SizedBox(width: SpacingTokens.sm),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ],
    );
  }
}
