import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/account.dart';
import 'package:qayd/domain/entities/voucher.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/domain/repositories/currency_repository.dart';
import 'package:qayd/domain/value_objects/account_classification.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';
import 'package:qayd/domain/value_objects/predefined_currencies.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:math';

// ─── Enums & Value Types ──────────────────────────────────────────────────────

/// How the user resolved a collision for a given legacy account.
enum ResolutionAction {
  /// Merge with an existing Qayd account (targetAccountId must be set).
  merge,

  /// Create a new Qayd account from the legacy data.
  createNew,

  /// Skip this account and all its transactions entirely.
  skip,
}

/// User decision for one legacy account during the conflict-resolution wizard.
class AccountResolution {
  /// The chosen action.
  final ResolutionAction action;

  /// Target Qayd account ID — required for [ResolutionAction.merge].
  final String? targetAccountId;

  const AccountResolution.merge(String qaydId)
      : action = ResolutionAction.merge,
        targetAccountId = qaydId;

  const AccountResolution.createNew()
      : action = ResolutionAction.createNew,
        targetAccountId = null;

  const AccountResolution.skip()
      : action = ResolutionAction.skip,
        targetAccountId = null;
}

// ─── Conflict Model ───────────────────────────────────────────────────────────

enum AccountConflictType {
  /// A Qayd account with the exact same name already exists.
  exactMatch,

  /// A Qayd account with the same phone was found (different name).
  partialMatch,

  /// No existing account could be matched — will be created fresh.
  noMatch,
}

class AccountMigrationConflict {
  final Map<String, dynamic> legacyData;
  final Account? existingAccount;
  final AccountConflictType type;

  /// Net balance per currency in the legacy system (positive = they owe us).
  final List<Map<String, dynamic>> legacyBalances;

  const AccountMigrationConflict({
    required this.legacyData,
    this.existingAccount,
    required this.type,
    this.legacyBalances = const [],
  });

  String get legacyIdStr => legacyData['legacy_id'].toString();
  String get name => legacyData['name']?.toString() ?? '';
  String get phone => legacyData['phone']?.toString() ?? '';
  String get groupName => legacyData['group_name']?.toString() ?? '';
}

// ─── Analysis Result ──────────────────────────────────────────────────────────

class MigrationAnalysisResult {
  final List<AccountMigrationConflict> accountConflicts;
  final Map<String, dynamic> stats;
  final Map<String, dynamic> rawBundle;

  const MigrationAnalysisResult({
    required this.accountConflicts,
    required this.stats,
    required this.rawBundle,
  });

  int get exactMatchCount => accountConflicts
      .where((c) => c.type == AccountConflictType.exactMatch)
      .length;

  int get partialMatchCount => accountConflicts
      .where((c) => c.type == AccountConflictType.partialMatch)
      .length;

  int get newAccountCount => accountConflicts
      .where((c) => c.type == AccountConflictType.noMatch)
      .length;
}

// ─── Use Case ─────────────────────────────────────────────────────────────────

class LegacyMigrationUseCase {
  final AccountRepository _accountRepo;
  final VoucherRepository _voucherRepo;
  final CurrencyRepository _currencyRepo;

  const LegacyMigrationUseCase(
    this._accountRepo,
    this._voucherRepo,
    this._currencyRepo,
  );

  // ── Phase 1: Analyse ────────────────────────────────────────────────────────

  /// Parses the JSON bundle (v1 or v2) and classifies every legacy account as
  /// exactMatch / partialMatch / noMatch against the current Qayd database.
  Future<Result<MigrationAnalysisResult>> analyzeBundle(
    String jsonContent,
  ) async {
    try {
      final bundle = json.decode(jsonContent) as Map<String, dynamic>;
      final legacyAccounts =
          (bundle['accounts'] as List? ?? []).cast<Map<String, dynamic>>();

      // Fetch all existing accounts once — avoids N+1 queries.
      final allResult = await _accountRepo.getAll();
      final allAccounts =
          allResult is Success<List<Account>> ? allResult.value : <Account>[];

      final conflicts = <AccountMigrationConflict>[];

      for (final legacy in legacyAccounts) {
        final name = legacy['name']?.toString().trim() ?? '';
        final phone =
            (legacy['phone'] ?? legacy['gsm'] ?? '').toString().trim();
        final legacyBalances =
            (legacy['balances'] as List? ?? []).cast<Map<String, dynamic>>();

        // 1. Try exact name match
        Account? existing = allAccounts
            .where((a) => a.name.trim().toLowerCase() == name.toLowerCase())
            .firstOrNull;

        // 2. Try phone match
        if (existing == null && phone.isNotEmpty) {
          final phoneResult = await _accountRepo.findAccountByPhone(phone);
          if (phoneResult is Success<AccountId?> && phoneResult.value != null) {
            final accResult = await _accountRepo.getById(phoneResult.value!);
            if (accResult is Success<Account>) existing = accResult.value;
          }
        }

        final conflictType = existing == null
            ? AccountConflictType.noMatch
            : (existing.name.trim().toLowerCase() == name.toLowerCase()
                ? AccountConflictType.exactMatch
                : AccountConflictType.partialMatch);

        conflicts.add(AccountMigrationConflict(
          legacyData: legacy,
          existingAccount: existing,
          type: conflictType,
          legacyBalances: legacyBalances,
        ));
      }

      return Success(MigrationAnalysisResult(
        accountConflicts: conflicts,
        stats: (bundle['stats'] as Map<String, dynamic>? ?? {}),
        rawBundle: bundle,
      ));
    } catch (e) {
      return FailureResult(
          UnexpectedFailure(messageAr: 'فشل في تحليل ملف الهجرة: $e'));
    }
  }

  // ── Phase 2: Create & Resolve Accounts ──────────────────────────────────────

  /// Creates new Qayd accounts for all [noMatch] conflicts (or conflicts where
  /// the user chose [ResolutionAction.createNew]), and builds the final
  /// `legacyId → qaydAccountId` mapping used by [executeImport].
  ///
  /// [userResolutions] — user choices keyed by legacy account ID string.
  Future<Result<Map<String, String>>> resolveAccounts({
    required MigrationAnalysisResult analysis,
    required Map<String, AccountResolution> userResolutions,
  }) async {
    final resolved = <String, String>{};

    for (final conflict in analysis.accountConflicts) {
      final legacyId = conflict.legacyIdStr;
      final decision =
          userResolutions[legacyId] ?? const AccountResolution.createNew();

      switch (decision.action) {
        case ResolutionAction.skip:
          // Do not add to map — transactions for this account will be skipped.
          break;

        case ResolutionAction.merge:
          resolved[legacyId] = decision.targetAccountId!;
          break;

        case ResolutionAction.createNew:
          // Build a minimal account from legacy data.
          final newId = AccountId(const Uuid().v4());
          final newAccount = Account.createRoot(
            id: newId,
            name: conflict.name.isNotEmpty ? conflict.name : 'حساب مستورد',
            // Legacy customer accounts are receivables (ذمم دائنة (عليك)) by default.
            // The user can reclassify later from inside the app.
            classification: AccountClassification.receivables,
            createdAt: DateTime.now(),
            metadata: {
              'source': 'legacy_import',
              'original_id': conflict.legacyData['legacy_id'],
              'group': conflict.groupName,
              if (conflict.phone.isNotEmpty) 'phone': conflict.phone,
            },
          );

          final saveResult = await _accountRepo.save(newAccount);
          if (saveResult is FailureResult) {
            return FailureResult(
              UnexpectedFailure(
                messageAr:
                    'فشل في إنشاء حساب "${conflict.name}": ${saveResult.failure.messageAr}',
              ),
            );
          }
          resolved[legacyId] = newId.value;
          break;
      }
    }

    return Success(resolved);
  }

  // ── Phase 3: Execute Import ──────────────────────────────────────────────────

  /// Imports all currencies and transactions from the bundle.
  ///
  /// [accountResolutions] — the final map from [resolveAccounts]:
  ///   legacy_id (string) → qayd account ID (string).
  /// Transactions whose counterparty is NOT in this map are silently skipped.
  ///
  /// Vouchers are created in **draft / pending** state so the account holder
  /// can review and confirm them individually inside the Qayd app.
  Future<Result<ImportSummary>> executeImport({
    required Map<String, dynamic> bundle,
    required Map<String, String> accountResolutions,
  }) async {
    try {
      // ── Locate fund account ──────────────────────────────────────────────
      final allResult = await _accountRepo.getAll();
      if (allResult is FailureResult<List<Account>>) {
        return FailureResult(allResult.failure);
      }
      final allAccounts = (allResult as Success<List<Account>>).value;
      final fundAccount = allAccounts
          .where((a) =>
              a.isDefault || a.name == 'الصندوق' || a.name.contains('قيد'))
          .firstOrNull;

      if (fundAccount == null) {
        return const FailureResult(
          UnexpectedFailure(
            messageAr:
                'تعذّر العثور على حساب الصندوق الرئيسي. تأكد من إعداد الحساب الافتراضي.',
          ),
        );
      }

      // ── Ensure required currencies exist ─────────────────────────────────
      final bundleCurrencies =
          (bundle['currencies'] as List? ?? []).cast<Map<String, dynamic>>();

      final currencyByCode = <String, CurrencyCode>{};

      for (final bc in bundleCurrencies) {
        final code = bc['mapped_code']?.toString() ?? 'USD';
        final existing = await _currencyRepo.getByCode(code);
        if (existing is Success<CurrencyCode?> && existing.value != null) {
          currencyByCode[code] = existing.value!;
        } else {
          // Auto-create using predefined catalogue or deduce.
          final predefined =
              PredefinedCurrencies.all.where((c) => c.code == code).firstOrNull;
          final currency = predefined ??
              CurrencyCode(
                code: code,
                nameAr: bc['name_ar']?.toString() ?? _fallbackNameAr(code),
                symbol: bc['symbol']?.toString() ?? _fallbackSymbol(code),
                fractionalDigits: 2,
              );
          await _currencyRepo.save(currency);
          currencyByCode[code] = currency;
        }
      }

      // Ensure we always have a fallback currency object for codes that came
      // from transactions but weren't in the currencies list.
      CurrencyCode resolveCurrency(String code) {
        return currencyByCode[code] ??
            CurrencyCode(
              code: code,
              nameAr: _fallbackNameAr(code),
              symbol: _fallbackSymbol(code),
              fractionalDigits: 2,
            );
      }

      // ── Import transactions ───────────────────────────────────────────────
      final legacyTransactions =
          (bundle['transactions'] as List? ?? []).cast<Map<String, dynamic>>();

      int imported = 0;
      int skipped = 0;
      int transfers = 0;

      for (final tx in legacyTransactions) {
        final cusLegacyId = tx['counterparty_legacy_id']?.toString() ?? '';
        final transferTargetId = tx['transfer_target_legacy_id'];
        final isTransfer = tx['type'] == 'transfer' && transferTargetId != null;

        // ── Regular receipt / payment ────────────────────────────────────
        if (!isTransfer) {
          final targetId = accountResolutions[cusLegacyId];
          if (targetId == null) {
            skipped++;
            continue;
          }

          final voucher = _buildVoucher(
            tx: tx,
            counterpartyId: AccountId(targetId),
            fundAccountId: fundAccount.id,
            resolveCurrency: resolveCurrency,
          );

          // Save as draft — user confirms in app (pending state).
          await _voucherRepo.save(voucher);
          imported++;
        } else {
          // ── Transfer: cus_id → t_cus_id through the fund ─────────────
          final fromId = accountResolutions[cusLegacyId];
          final toIdStr = transferTargetId.toString();
          final toId = accountResolutions[toIdStr];

          // Create receipt leg (from → fund)
          if (fromId != null) {
            final receiptVoucher = _buildVoucher(
              tx: tx,
              counterpartyId: AccountId(fromId),
              fundAccountId: fundAccount.id,
              resolveCurrency: resolveCurrency,
              forceType: VoucherType.receipt,
              extraNotes:
                  'تحويل إلى: ${_lookupAccountName(legacyTransactions, toIdStr)}',
            );
            await _voucherRepo.save(receiptVoucher);
            imported++;
          }

          // Create payment leg (fund → to)
          if (toId != null) {
            final paymentVoucher = _buildVoucher(
              tx: tx,
              counterpartyId: AccountId(toId),
              fundAccountId: fundAccount.id,
              resolveCurrency: resolveCurrency,
              forceType: VoucherType.payment,
              extraNotes:
                  'تحويل من: ${_lookupAccountName(legacyTransactions, cusLegacyId)}',
            );
            await _voucherRepo.save(paymentVoucher);
            imported++;
          }

          transfers++;
          if (fromId == null && toId == null) skipped++;
        }
      }

      return Success(ImportSummary(
        imported: imported,
        skipped: skipped,
        transfers: transfers,
      ));
    } catch (e) {
      return FailureResult(
          UnexpectedFailure(messageAr: 'فشل في استيراد البيانات: $e'));
    }
  }

  // ── Private Helpers ─────────────────────────────────────────────────────────

  Voucher _buildVoucher({
    required Map<String, dynamic> tx,
    required AccountId counterpartyId,
    required AccountId fundAccountId,
    required CurrencyCode Function(String) resolveCurrency,
    VoucherType? forceType,
    String? extraNotes,
  }) {
    final typeStr = tx['type']?.toString() ?? 'receipt';
    final voucherType = forceType ??
        (typeStr == 'payment' ? VoucherType.payment : VoucherType.receipt);

    final currCode = tx['currency_code']?.toString() ?? 'YER';
    final currency = resolveCurrency(currCode);
    final amount = (tx['amount_raw'] as num? ?? 0).toDouble();
    final money = _toMoney(amount, currency);

    // Prefer the pre-parsed ISO date from v2 bundle, fall back to raw.
    final dateParsed =
        tx['date_parsed']?.toString() ?? tx['date']?.toString() ?? '';
    final date = _parseIsoDate(dateParsed) ?? DateTime.now();

    final description = tx['description']?.toString() ?? '';
    final legacyId = tx['legacy_id']?.toString() ?? '';

    final notes = [
      'مستورد من النظام القديم (ID: $legacyId)',
      if (extraNotes != null) extraNotes,
    ].join(' | ');

    // Voucher is saved as DRAFT — the account holder must confirm it.
    return Voucher.draft(
      id: VoucherId(const Uuid().v4()),
      type: voucherType,
      date: date,
      amount: money,
      currency: currency,
      counterpartyId: counterpartyId,
      affectedAccountId: fundAccountId,
      createdAt: DateTime.now(),
      description: description,
      notes: notes,
    );
  }

  Money _toMoney(double decimal, CurrencyCode currency) {
    final digits =
        currency.fractionalDigits > 0 ? currency.fractionalDigits : 2;
    final minor = (decimal * pow(10, digits)).round();
    return Money.positiveAmount(minor, currency);
  }

  /// Parses yyyy-mm-dd produced by the web tool. Tolerates missing values.
  DateTime? _parseIsoDate(String s) {
    if (s.isEmpty) return null;
    try {
      // yyyy-mm-dd
      if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(s)) {
        return DateTime.parse('${s.substring(0, 10)}T00:00:00');
      }
      // dd-mm-yyyy (legacy raw)
      if (RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(s)) {
        final p = s.split('-');
        return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
      }
    } catch (_) {}
    return null;
  }

  String _fallbackNameAr(String code) {
    const map = {
      'SAR': 'ريال سعودي',
      'YER': 'ريال يمني',
      'USD': 'دولار أمريكي',
      'EGP': 'جنيه مصري',
      'AED': 'درهم إماراتي',
      'KWD': 'دينار كويتي',
      'QAR': 'ريال قطري',
      'OMR': 'ريال عماني',
      'BHD': 'دينار بحريني',
      'JOD': 'دينار أردني',
      'EUR': 'يورو',
      'GBP': 'جنيه إسترليني',
    };
    return map[code] ?? 'عملة $code';
  }

  String _fallbackSymbol(String code) {
    const map = {
      'SAR': '﷼',
      'YER': '﷼',
      'QAR': '﷼',
      'OMR': '﷼',
      'USD': r'$',
      'EUR': '€',
      'GBP': '£',
      'EGP': 'ج.م',
      'AED': 'د.إ',
      'KWD': 'د.ك',
      'BHD': 'د.ب',
      'JOD': 'د.أ',
    };
    return map[code] ?? code;
  }

  /// Best-effort lookup of an account name by legacy ID from the transaction list.
  String _lookupAccountName(
      List<Map<String, dynamic>> txList, String legacyId) {
    return legacyId;
  }
}

// ─── Import Summary ───────────────────────────────────────────────────────────

class ImportSummary {
  final int imported;
  final int skipped;
  final int transfers;

  const ImportSummary({
    required this.imported,
    required this.skipped,
    required this.transfers,
  });

  @override
  String toString() =>
      'تم استيراد $imported سند، تخطي $skipped، منها $transfers تحويل.';
}
