import 'package:flutter/foundation.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:qayd/application/accounts/batch_import_accounts_from_csv_use_case.dart';
import 'package:qayd/application/accounts/create_account_use_case.dart';
import 'package:qayd/application/accounts/deactivate_account_use_case.dart';
import 'package:qayd/application/accounts/get_account_details_use_case.dart';
import 'package:qayd/application/accounts/get_account_statement_use_case.dart';
import 'package:qayd/application/accounts/list_account_statement_chat_use_case.dart';
import 'package:qayd/application/accounts/list_accounts_use_case.dart';
import 'package:qayd/application/accounts/update_account_use_case.dart';
import 'package:qayd/application/governance/check_governance_status_use_case.dart';
import 'package:qayd/application/governance/governance_write_guard.dart';
import 'package:qayd/application/governance/submit_activation_use_case.dart';
import 'package:qayd/application/messaging/create_message_template_use_case.dart';
import 'package:qayd/application/messaging/delete_message_template_use_case.dart';
import 'package:qayd/application/messaging/list_message_templates_use_case.dart';
import 'package:qayd/application/messaging/log_notification_intent_use_case.dart';
import 'package:qayd/application/reports/generate_trial_balance_use_case.dart';
import 'package:qayd/application/settings/get_active_transaction_fee_use_case.dart';
import 'package:qayd/application/settings/manage_transaction_fee_use_case.dart';
import 'package:qayd/application/settings/get_base_currency_use_case.dart';
import 'package:qayd/application/settings/list_currencies_use_case.dart';
import 'package:qayd/application/settings/set_base_currency_use_case.dart';
import 'package:qayd/application/settings/toggle_currency_status_use_case.dart';
import 'package:qayd/application/settings/add_currency_use_case.dart';
import 'package:qayd/application/suggestions/get_auto_suggestions_use_case.dart';
import 'package:qayd/application/suggestions/mark_notification_message_processed_use_case.dart';
import 'package:qayd/application/messaging/save_message_template_use_case.dart';
import 'package:qayd/application/vouchers/accept_voucher_use_case.dart';
import 'package:qayd/application/vouchers/confirm_voucher_use_case.dart';
import 'package:qayd/application/vouchers/reject_voucher_use_case.dart';
import 'package:qayd/application/vouchers/resubmit_voucher_use_case.dart';
import 'package:qayd/application/vouchers/create_tripartite_transfer_use_case.dart';
import 'package:qayd/application/vouchers/create_voucher_use_case.dart';
import 'package:qayd/application/accounts/find_account_by_phone_use_case.dart';
import 'package:qayd/application/identity/lookup_public_key_use_case.dart';
import 'package:qayd/application/identity/setup_identity_use_case.dart';
import 'package:qayd/application/vouchers/get_voucher_details_use_case.dart';
import 'package:qayd/application/vouchers/list_vouchers_use_case.dart';
import 'package:qayd/application/vouchers/update_draft_voucher_use_case.dart';
import 'package:qayd/core/utils/id_generator.dart';
import 'package:qayd/data/backup/auto_backup_service.dart';
import 'package:qayd/data/backup/backup_service.dart';
import 'package:qayd/data/backup/google_drive_backup_service.dart';
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
import 'package:qayd/data/repositories/sqlite_transaction_fee_settings_repository.dart';
import 'package:qayd/data/repositories/sqlite_voucher_repository.dart';
import 'package:qayd/data/security/app_pin_storage.dart';
import 'package:qayd/data/security/hardware_id_service.dart';
import 'package:qayd/data/security/license_vault.dart';
import 'package:qayd/data/security/monotonic_clock_guard.dart';
import 'package:qayd/data/security/panic_wipe_service.dart';
import 'package:qayd/domain/repositories/auth_repository.dart';
import 'package:qayd/domain/repositories/identity_repository.dart';
import 'package:qayd/domain/repositories/currency_repository.dart';
import 'package:qayd/domain/repositories/message_template_repository.dart';
import 'package:qayd/domain/repositories/notification_log_repository.dart';
import 'package:qayd/domain/repositories/notification_message_repository.dart';
import 'package:qayd/domain/repositories/transaction_fee_settings_repository.dart';
import 'package:qayd/domain/services/voucher_qr_service.dart';
import 'package:qayd/domain/services/receipt_signing_service.dart';
import 'package:qayd/domain/services/balance_calculator.dart';
import 'package:qayd/domain/services/entry_generator.dart';
import 'package:qayd/domain/services/trial_balance_generator.dart';
import 'package:qayd/presentation/security/security_cubit.dart';
import 'package:qayd/data/security/ed25519_identity_service.dart';
import 'package:qayd/data/security/identity_file_storage.dart';
import 'package:qayd/data/security/mnemonic_vault.dart';
import 'package:qayd/data/repositories/remote_identity_repository.dart';
import 'package:qayd/domain/services/crypto_identity_service.dart';
import 'package:qayd/application/sync/sync_coordinator_service.dart';
import 'package:qayd/application/sync/sync_payload_processor.dart';
import 'package:qayd/data/network/sync_socket_service.dart';
import 'package:qayd/domain/services/native_notification_service.dart';
import 'package:qayd/data/services/local_notification_service_impl.dart';
import 'package:qayd/data/repositories/api_sync_repository.dart';
import 'package:qayd/data/security/e2ee_encryption_service_impl.dart';
import 'package:qayd/domain/services/e2ee_encryption_service.dart';
import 'package:qayd/domain/repositories/sync_repository.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/domain/repositories/ledger_repository.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qayd/domain/repositories/app_config_repository.dart';
import 'package:qayd/data/repositories/api_app_config_repository.dart';

/// Composition root: encrypted DB, repositories, and use cases.
abstract final class InjectionContainer {
  static final UuidV4IdGenerator _idGenerator = UuidV4IdGenerator();

  static late DatabaseEncryptionKeyProvider _encryptionKeyProvider;

  /// Bumps after [reopenDatabaseAfterRestore] so the UI tree can rebuild.
  static final ValueNotifier<int> databaseEpoch = ValueNotifier<int>(0);

  /// Not `final`: replaced after a successful restore ([reopenDatabaseAfterRestore]).
  static late Database database;

  static late final BackupService backupService;
  static late final AutoBackupService autoBackupService;
  static late final GoogleDriveBackupService driveBackupService;
  static late final IdentityFileStorage identityFileStorage;

  // ── Phase 7: Security services ─────────────────────────────────────────────

  static late final AppPinStorage appPinStorage;
  static late final LicenseVault licenseVault;
  static late final HardwareIdService hardwareIdService;
  static late final MonotonicClockGuard clockGuard;
  static late final PanicWipeService panicWipeService;
  static late final AuthRepository authRepository;

  /// The unified security cubit — shared by [main.dart].
  static late final SecurityCubit securityCubit;

  // ── Cryptographic identity ─────────────────────────────────────────────

  static late final CryptoIdentityService cryptoIdentityService;
  static late final MnemonicVault mnemonicVault;
  static late final IdentityRepository identityRepository;
  static late final SetupIdentityUseCase setupIdentityUseCase;
  static late final LookupPublicKeyUseCase lookupPublicKeyUseCase;
  static late final ReceiptSigningService receiptSigningService;

  // ── Governance ─────────────────────────────────────────────────────────────

  static late final GovernanceStubController governanceStubController;
  static late final CheckGovernanceStatusUseCase checkGovernanceStatusUseCase;
  static late final SubmitActivationUseCase submitActivationUseCase;
  static late final GovernanceWriteGuard governanceWriteGuard;

  // ── Accounting Repositories (Static for Sync access) ──────────────────────

  static late final AccountRepository accountRepository;
  static late final LedgerRepository ledgerRepository;
  static late final VoucherRepository voucherRepository;
  static late final CurrencyRepository currencyRepository;

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
  static late final ListAccountStatementChatUseCase
      listAccountStatementChatUseCase;
  static late final CreateVoucherUseCase createVoucherUseCase;
  static late final CreateTripartiteTransferUseCase
      createTripartiteTransferUseCase;
  static late final UpdateDraftVoucherUseCase updateDraftVoucherUseCase;
  static late final AcceptVoucherUseCase acceptVoucherUseCase;
  static late final ConfirmVoucherUseCase confirmVoucherUseCase;
  static late final RejectVoucherUseCase rejectVoucherUseCase;
  static late final ResubmitVoucherUseCase resubmitVoucherUseCase;
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
  static late final ListCurrenciesUseCase listCurrenciesUseCase;
  static late final GetBaseCurrencyUseCase getBaseCurrencyUseCase;
  static late final SetBaseCurrencyUseCase setBaseCurrencyUseCase;
  static late final ToggleCurrencyStatusUseCase toggleCurrencyStatusUseCase;
  static late final AddCurrencyUseCase addCurrencyUseCase;
  static late final TransactionFeeSettingsRepository
      transactionFeeSettingsRepository;
  static late final GetActiveTransactionFeeUseCase
      getActiveTransactionFeeUseCase;
  static late final ManageTransactionFeeUseCase manageTransactionFeeUseCase;

  // ── Sync & Real-Time Components ──────────────────────────────────────────

  static late final NativeNotificationService nativeNotificationService;
  static late final SyncCoordinatorService syncCoordinatorService;
  static late final SyncSocketService syncSocketService;
  static late final SyncPayloadProcessor syncPayloadProcessor;
  static late final SyncRepository syncRepository;
  static late final E2EEEncryptionService e2eeService;

  // ── App Settings & Info ────────────────────────────────────────────────
  static late final SharedPreferences sharedPreferences;
  static late final AppConfigRepository appConfigRepository;

  static Future<void> init({
    DatabaseEncryptionKeyProvider? encryptionKeyProvider,
  }) async {
    // ── Phase 7: Security bootstrap ─────────────────────────────────────────

    appPinStorage = AppPinStorage();
    licenseVault = LicenseVault();
    hardwareIdService = HardwareIdService();
    clockGuard = MonotonicClockGuard();

    final hwId = await hardwareIdService.obtainHardwareId();
    identityFileStorage = IdentityFileStorage(hardwareId: hwId);

    panicWipeService = PanicWipeService(
      licenseVault: licenseVault,
      clockGuard: clockGuard,
      pinStorage: appPinStorage,
      identityFileStorage: identityFileStorage,
    );
    final apiClient = ApiClient(
      baseUrl: ApiEndpoints.baseUrl,
      tokenProvider: () => null,
    );
    authRepository = RemoteAuthRepository(apiClient: apiClient);

    sharedPreferences = await SharedPreferences.getInstance();
    appConfigRepository = ApiAppConfigRepository(
      apiClient: apiClient,
      sharedPreferences: sharedPreferences,
    );

    securityCubit = SecurityCubit(
      pinStorage: appPinStorage,
      licenseVault: licenseVault,
      hardwareIdService: hardwareIdService,
      clockGuard: clockGuard,
      panicWipeService: panicWipeService,
      authRepository: authRepository,
    );

    // ── Cryptographic identity ─────────────────────────────────────────────

    cryptoIdentityService = const Ed25519IdentityService();
    mnemonicVault = MnemonicVault();
    identityRepository = RemoteIdentityRepository(apiClient: apiClient);
    setupIdentityUseCase = SetupIdentityUseCase(
      cryptoService: cryptoIdentityService,
      mnemonicVault: mnemonicVault,
      identityRepository: identityRepository,
      identityFileStorage: identityFileStorage,
    );
    lookupPublicKeyUseCase = LookupPublicKeyUseCase(
      identityRepository: identityRepository,
    );
    receiptSigningService = ReceiptSigningService(
      cryptoService: cryptoIdentityService,
    );

    if (!await mnemonicVault.hasIdentity()) {
      await identityFileStorage.restoreToVaultIfAvailable(mnemonicVault);
    }

    // ── Encryption key provider ─────────────────────────────────────────────

    _encryptionKeyProvider = encryptionKeyProvider ??
        HardwareBackedEncryptionKeyProvider(
          hardwareIdService: hardwareIdService,
          licenseVault: licenseVault,
        );

    backupService = BackupService(keyProvider: _encryptionKeyProvider);
    autoBackupService = AutoBackupService();
    driveBackupService = GoogleDriveBackupService();
    database = await DatabaseProvider.open(keyProvider: _encryptionKeyProvider);

    autoBackupService.performIfDue().ignore();
    driveBackupService.performIfDue().ignore();

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

    // ── Native Notifications & E2EE Service ──────────────────────────────────
    nativeNotificationService = LocalNotificationServiceImpl();
    await nativeNotificationService.initialize();
    e2eeService = const E2EEEncryptionServiceImpl();

    _registerSqliteStack();

    // ── Real-Time Sync Engine ────────────────────────────────────────────────
    syncRepository = ApiSyncRepository(apiClient);
    
    // Attempt to read JWT for WebSocket authentication
    final jwt = await licenseVault.readJwt();

    syncSocketService = SyncSocketService(
      wsUrl: 'wss://qayd-qq6w.onrender.com/ws', 
      tokenProvider: () => jwt,
    );
    
    syncPayloadProcessor = SyncPayloadProcessor(
      identityRepository: identityRepository,
      voucherRepository: voucherRepository,
      ledgerRepository: ledgerRepository,
      accountRepository: accountRepository,
      e2eeService: e2eeService,
      signingService: receiptSigningService,
      getCurrentUserKeyPair: () => setupIdentityUseCase.getKeyPair().then((v) => v!), 
    );

    syncCoordinatorService = SyncCoordinatorService(
      syncRepository: syncRepository,
      socketService: syncSocketService,
      payloadProcessor: syncPayloadProcessor,
      nativeNotificationService: nativeNotificationService,
      currentUserId: 1, // Placeholder: in production, decode ID from JWT
    );

    // Initialize the background sync lifecycle
    syncCoordinatorService.start();
  }

  static Future<void> closeDatabaseForRestore() async {
    await database.close();
  }

  static Future<void> reopenDatabaseAfterRestore() async {
    database = await DatabaseProvider.open(keyProvider: _encryptionKeyProvider);
    _registerSqliteStack();
    databaseEpoch.value++;
  }

  static void _registerSqliteStack() {
    accountRepository = SqliteAccountRepository(database);
    ledgerRepository = SqliteLedgerRepository(database);
    final transactionRunner = DatabaseTransactionRunner(database);
    voucherRepository = SqliteVoucherRepository(
      database,
      transactionRunner,
    );
    currencyRepository = SqliteCurrencyRepository(database);
    const balanceCalculator = BalanceCalculator();
    const entryGenerator = EntryGenerator();
    const trialBalanceGenerator = TrialBalanceGenerator();
    const voucherQrService = VoucherQrService();

    transactionFeeSettingsRepository =
        SqliteTransactionFeeSettingsRepository(database);
    getActiveTransactionFeeUseCase =
        GetActiveTransactionFeeUseCase(transactionFeeSettingsRepository);
    manageTransactionFeeUseCase = ManageTransactionFeeUseCase(
      transactionFeeSettingsRepository,
      _idGenerator,
    );

    listCurrenciesUseCase = ListCurrenciesUseCase(currencyRepository);
    getBaseCurrencyUseCase = GetBaseCurrencyUseCase(currencyRepository);
    setBaseCurrencyUseCase = SetBaseCurrencyUseCase(currencyRepository);
    toggleCurrencyStatusUseCase = ToggleCurrencyStatusUseCase(currencyRepository);
    addCurrencyUseCase = AddCurrencyUseCase(currencyRepository);

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
    findAccountByPhoneUseCase = FindAccountByPhoneUseCase(accountRepository);
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
    listAccountStatementChatUseCase = ListAccountStatementChatUseCase(
      accountRepository: accountRepository,
      voucherRepository: voucherRepository,
    );
    createVoucherUseCase = CreateVoucherUseCase(
      voucherRepository,
      currencyRepository,
      _idGenerator,
      governanceWriteGuard,
    );
    createTripartiteTransferUseCase = CreateTripartiteTransferUseCase(
      voucherRepository,
      currencyRepository,
      _idGenerator,
      governanceWriteGuard,
      getActiveTransactionFeeUseCase,
      accountRepository,
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
    rejectVoucherUseCase = RejectVoucherUseCase(
      voucherRepository,
      governanceWriteGuard,
    );
    resubmitVoucherUseCase = ResubmitVoucherUseCase(
      voucherRepository,
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
        GetAutoSuggestionsUseCase(notificationMessageRepository, voucherRepository);
    markNotificationMessageProcessedUseCase =
        MarkNotificationMessageProcessedUseCase(notificationMessageRepository);
    logNotificationIntentUseCase = LogNotificationIntentUseCase(
      notificationLogRepository,
      notificationMessageRepository,
      _idGenerator,
    );
  }
}
