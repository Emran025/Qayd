import 'package:qayd/application/accounts/batch_import_accounts_from_csv_use_case.dart';
import 'package:qayd/application/accounts/create_account_use_case.dart';
import 'package:qayd/application/accounts/deactivate_account_use_case.dart';
import 'package:qayd/application/accounts/get_account_details_use_case.dart';
import 'package:qayd/application/accounts/get_account_statement_use_case.dart';
import 'package:qayd/application/accounts/list_accounts_use_case.dart';
import 'package:qayd/application/accounts/update_account_use_case.dart';
import 'package:qayd/application/governance/check_governance_status_use_case.dart';
import 'package:qayd/application/governance/governance_write_guard.dart';
import 'package:qayd/application/governance/submit_activation_use_case.dart';
import 'package:qayd/application/messaging/create_message_template_use_case.dart';
import 'package:qayd/application/messaging/delete_message_template_use_case.dart';
import 'package:qayd/application/messaging/list_message_templates_use_case.dart';
import 'package:qayd/application/messaging/log_notification_intent_use_case.dart';
import 'package:qayd/application/settings/get_base_currency_use_case.dart';
import 'package:qayd/application/settings/list_currencies_use_case.dart';
import 'package:qayd/application/settings/set_base_currency_use_case.dart';
import 'package:qayd/application/suggestions/get_auto_suggestions_use_case.dart';
import 'package:qayd/application/suggestions/mark_notification_message_processed_use_case.dart';
import 'package:qayd/application/messaging/save_message_template_use_case.dart';
import 'package:qayd/application/reports/generate_trial_balance_use_case.dart';
import 'package:qayd/application/vouchers/confirm_voucher_use_case.dart';
import 'package:qayd/application/vouchers/create_voucher_use_case.dart';
import 'package:qayd/application/accounts/find_account_by_phone_use_case.dart';
import 'package:qayd/application/vouchers/get_voucher_details_use_case.dart';
import 'package:qayd/application/vouchers/list_vouchers_use_case.dart';
import 'package:qayd/application/vouchers/update_draft_voucher_use_case.dart';
import 'package:qayd/core/utils/id_generator.dart';
import 'package:qayd/data/backup/backup_service.dart';
import 'package:qayd/data/database/database_encryption_key_provider.dart';
import 'package:qayd/data/database/database_provider.dart';
import 'package:qayd/data/database/hardware_backed_encryption_key_provider.dart';
import 'package:qayd/data/database/transaction_runner.dart';
import 'package:qayd/data/governance/remote/governance_stub_controller.dart';
import 'package:qayd/data/governance/remote/stub_governance_remote_data_source.dart';
import 'package:qayd/core/constants/api_endpoints.dart';
import 'package:qayd/data/network/api_client.dart';
import 'package:qayd/data/repositories/governance_repository_impl.dart';
import 'package:qayd/data/repositories/remote_auth_repository.dart';
import 'package:qayd/data/repositories/sqlite_account_repository.dart';
import 'package:qayd/data/repositories/sqlite_ledger_repository.dart';
import 'package:qayd/data/repositories/sqlite_message_template_repository.dart';
import 'package:qayd/data/repositories/sqlite_notification_log_repository.dart';
import 'package:qayd/data/repositories/sqlite_notification_message_repository.dart';
import 'package:qayd/data/pdf/account_statement_pdf_generator.dart';
import 'package:qayd/data/pdf/cairo_voucher_pdf_generator.dart';
import 'package:qayd/data/pdf/voucher_pdf_generator.dart';
import 'package:qayd/data/repositories/sqlite_currency_repository.dart';
import 'package:qayd/data/repositories/sqlite_voucher_repository.dart';
import 'package:qayd/data/security/app_pin_storage.dart';
import 'package:qayd/data/security/hardware_id_service.dart';
import 'package:qayd/data/security/license_vault.dart';
import 'package:qayd/data/security/monotonic_clock_guard.dart';
import 'package:qayd/data/security/panic_wipe_service.dart';
import 'package:qayd/domain/repositories/auth_repository.dart';
import 'package:qayd/domain/repositories/currency_repository.dart';
import 'package:qayd/domain/repositories/message_template_repository.dart';
import 'package:qayd/domain/repositories/notification_log_repository.dart';
import 'package:qayd/domain/repositories/notification_message_repository.dart';
import 'package:qayd/domain/services/voucher_qr_service.dart';
import 'package:qayd/domain/services/balance_calculator.dart';
import 'package:qayd/domain/services/entry_generator.dart';
import 'package:qayd/domain/services/trial_balance_generator.dart';
import 'package:qayd/presentation/security/security_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';


/// Composition root: encrypted DB, repositories, and use cases.
abstract final class InjectionContainer {
  static final UuidV4IdGenerator _idGenerator = UuidV4IdGenerator();

  static late DatabaseEncryptionKeyProvider _encryptionKeyProvider;

  /// Bumps after [reopenDatabaseAfterRestore] so the UI tree can rebuild.
  static final ValueNotifier<int> databaseEpoch = ValueNotifier<int>(0);

  /// Not `final`: replaced after a successful restore ([reopenDatabaseAfterRestore]).
  static late Database database;

  static late final BackupService backupService;

  // ── Phase 7: Security services ─────────────────────────────────────────────

  static late final AppPinStorage appPinStorage;
  static late final LicenseVault licenseVault;
  static late final HardwareIdService hardwareIdService;
  static late final MonotonicClockGuard clockGuard;
  static late final PanicWipeService panicWipeService;
  static late final AuthRepository authRepository;

  /// The unified security cubit — shared by [main.dart].
  static late final SecurityCubit securityCubit;

  // ── Governance ─────────────────────────────────────────────────────────────

  static late final GovernanceStubController governanceStubController;
  static late final CheckGovernanceStatusUseCase checkGovernanceStatusUseCase;
  static late final SubmitActivationUseCase submitActivationUseCase;
  static late final GovernanceWriteGuard governanceWriteGuard;

  // ── Accounting use cases ───────────────────────────────────────────────────

  static late final CreateAccountUseCase createAccountUseCase;
  static late final BatchImportAccountsFromCsvUseCase
      batchImportAccountsFromCsvUseCase;
  static late final UpdateAccountUseCase updateAccountUseCase;
  static late final DeactivateAccountUseCase deactivateAccountUseCase;
  static late final GetAccountDetailsUseCase getAccountDetailsUseCase;
  static late final FindAccountByPhoneUseCase findAccountByPhoneUseCase;
  static late final ListAccountsUseCase listAccountsUseCase;
  static late final GetAccountStatementUseCase getAccountStatementUseCase;
  static late final CreateVoucherUseCase createVoucherUseCase;
  static late final UpdateDraftVoucherUseCase updateDraftVoucherUseCase;
  static late final ConfirmVoucherUseCase confirmVoucherUseCase;
  static late final ListVouchersUseCase listVouchersUseCase;
  static late final GetVoucherDetailsUseCase getVoucherDetailsUseCase;
  static late final GenerateTrialBalanceUseCase generateTrialBalanceUseCase;
  static late final VoucherPdfGenerator voucherPdfGenerator;
  static late final AccountStatementPdfGenerator accountStatementPdfGenerator;

  static late final MessageTemplateRepository messageTemplateRepository;
  static late final NotificationLogRepository notificationLogRepository;
  static late final ListMessageTemplatesUseCase listMessageTemplatesUseCase;
  static late final SaveMessageTemplateUseCase saveMessageTemplateUseCase;
  static late final DeleteMessageTemplateUseCase deleteMessageTemplateUseCase;
  static late final CreateMessageTemplateUseCase createMessageTemplateUseCase;
  static late final LogNotificationIntentUseCase logNotificationIntentUseCase;
  static late final NotificationMessageRepository notificationMessageRepository;
  static late final GetAutoSuggestionsUseCase getAutoSuggestionsUseCase;
  static late final MarkNotificationMessageProcessedUseCase
      markNotificationMessageProcessedUseCase;
  static late final CurrencyRepository currencyRepository;
  static late final ListCurrenciesUseCase listCurrenciesUseCase;
  static late final GetBaseCurrencyUseCase getBaseCurrencyUseCase;
  static late final SetBaseCurrencyUseCase setBaseCurrencyUseCase;

  static Future<void> init({
    DatabaseEncryptionKeyProvider? encryptionKeyProvider,
  }) async {
    // ── Phase 7: Security bootstrap ─────────────────────────────────────────

    appPinStorage = AppPinStorage();
    licenseVault = LicenseVault();
    hardwareIdService = HardwareIdService();
    clockGuard = MonotonicClockGuard();
    panicWipeService = PanicWipeService(
      licenseVault: licenseVault,
      clockGuard: clockGuard,
      pinStorage: appPinStorage,
    );
    final apiClient = ApiClient(
      baseUrl: ApiEndpoints.baseUrl,
      // Attach the stored JWT on every authenticated request.
      tokenProvider: () {
        // Fire-and-forget — the vault read is async, but we return null
        // synchronously for unauthenticated requests (login/register).
        // Authenticated requests use AuthInterceptor which reads the stored
        // token via a synchronous cache updated by LicenseVault.
        return null; // Token is written to vault; add sync cache in Phase 8 if needed.
      },
    );
    authRepository = RemoteAuthRepository(apiClient: apiClient);

    securityCubit = SecurityCubit(
      pinStorage: appPinStorage,
      licenseVault: licenseVault,
      hardwareIdService: hardwareIdService,
      clockGuard: clockGuard,
      panicWipeService: panicWipeService,
      authRepository: authRepository,
    );

    // ── Encryption key provider ─────────────────────────────────────────────

    _encryptionKeyProvider = encryptionKeyProvider ??
        HardwareBackedEncryptionKeyProvider(
          hardwareIdService: hardwareIdService,
          licenseVault: licenseVault,
        );

    backupService = BackupService(keyProvider: _encryptionKeyProvider);
    database = await DatabaseProvider.open(keyProvider: _encryptionKeyProvider);

    // ── Governance ──────────────────────────────────────────────────────────

    governanceStubController = GovernanceStubController();
    final governanceRemote = StubGovernanceRemoteDataSource(
      controller: governanceStubController,
    );
    final governanceRepository = GovernanceRepositoryImpl(governanceRemote);
    checkGovernanceStatusUseCase =
        CheckGovernanceStatusUseCase(governanceRepository);
    submitActivationUseCase = SubmitActivationUseCase(governanceRepository);
    governanceWriteGuard = GovernanceWriteGuard(checkGovernanceStatusUseCase);

    _registerSqliteStack();
  }

  /// Call before replacing `qayd_finance.db` on disk (restore).
  static Future<void> closeDatabaseForRestore() async {
    await database.close();
  }

  /// Reopens the DB and rewires SQLite-backed services after [closeDatabaseForRestore].
  static Future<void> reopenDatabaseAfterRestore() async {
    database = await DatabaseProvider.open(keyProvider: _encryptionKeyProvider);
    _registerSqliteStack();
    databaseEpoch.value++;
  }

  static void _registerSqliteStack() {
    final accountRepository = SqliteAccountRepository(database);
    final ledgerRepository = SqliteLedgerRepository(database);
    final transactionRunner = DatabaseTransactionRunner(database);
    final voucherRepository = SqliteVoucherRepository(
      database,
      transactionRunner,
    );
    currencyRepository = SqliteCurrencyRepository(database);
    const balanceCalculator = BalanceCalculator();
    const entryGenerator = EntryGenerator();
    const trialBalanceGenerator = TrialBalanceGenerator();
    const voucherQrService = VoucherQrService();

    listCurrenciesUseCase = ListCurrenciesUseCase(currencyRepository);
    getBaseCurrencyUseCase = GetBaseCurrencyUseCase(currencyRepository);
    setBaseCurrencyUseCase = SetBaseCurrencyUseCase(currencyRepository);

    createAccountUseCase = CreateAccountUseCase(
      accountRepository,
      _idGenerator,
      governanceWriteGuard,
    );
    batchImportAccountsFromCsvUseCase =
        BatchImportAccountsFromCsvUseCase(createAccountUseCase);
    updateAccountUseCase = UpdateAccountUseCase(
      accountRepository,
      governanceWriteGuard,
    );
    deactivateAccountUseCase = DeactivateAccountUseCase(
      accountRepository,
      ledgerRepository,
      balanceCalculator,
      governanceWriteGuard,
    );
    getAccountDetailsUseCase = GetAccountDetailsUseCase(
      accountRepository,
      ledgerRepository,
      balanceCalculator,
    );
    findAccountByPhoneUseCase = FindAccountByPhoneUseCase(
      accountRepository,
    );
    listAccountsUseCase = ListAccountsUseCase(
      accountRepository,
      ledgerRepository,
      balanceCalculator,
    );
    getAccountStatementUseCase = GetAccountStatementUseCase(
      accountRepository,
      ledgerRepository,
      voucherRepository,
    );
    createVoucherUseCase = CreateVoucherUseCase(
      voucherRepository,
      currencyRepository,
      _idGenerator,
      governanceWriteGuard,
    );
    updateDraftVoucherUseCase = UpdateDraftVoucherUseCase(
      voucherRepository,
      currencyRepository,
      governanceWriteGuard,
    );
    confirmVoucherUseCase = ConfirmVoucherUseCase(
      voucherRepository,
      entryGenerator,
      _idGenerator,
      governanceWriteGuard,
    );
    listVouchersUseCase = ListVouchersUseCase(
      voucherRepository,
      accountRepository,
    );
    getVoucherDetailsUseCase = GetVoucherDetailsUseCase(
      voucherRepository,
      accountRepository,
      voucherQrService,
      licenseVault,
    );
    generateTrialBalanceUseCase = GenerateTrialBalanceUseCase(
      accountRepository,
      ledgerRepository,
      trialBalanceGenerator,
    );
    voucherPdfGenerator = const CairoVoucherPdfGenerator();
    accountStatementPdfGenerator = const CairoAccountStatementPdfGenerator();

    messageTemplateRepository = SqliteMessageTemplateRepository(database);
    notificationLogRepository = SqliteNotificationLogRepository(database);
    notificationMessageRepository =
        SqliteNotificationMessageRepository(database);
    listMessageTemplatesUseCase =
        ListMessageTemplatesUseCase(messageTemplateRepository);
    saveMessageTemplateUseCase =
        SaveMessageTemplateUseCase(messageTemplateRepository);
    deleteMessageTemplateUseCase =
        DeleteMessageTemplateUseCase(messageTemplateRepository);
    createMessageTemplateUseCase = CreateMessageTemplateUseCase(
      messageTemplateRepository,
      _idGenerator,
    );
    getAutoSuggestionsUseCase =
        GetAutoSuggestionsUseCase(notificationMessageRepository);
    markNotificationMessageProcessedUseCase =
        MarkNotificationMessageProcessedUseCase(notificationMessageRepository);
    logNotificationIntentUseCase = LogNotificationIntentUseCase(
      notificationLogRepository,
      notificationMessageRepository,
      _idGenerator,
    );
  }
}
