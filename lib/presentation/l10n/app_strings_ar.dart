import 'package:qayd/presentation/l10n/string_keys.dart';

/// Arabic user-facing strings (primary locale).
abstract final class AppStringsAr {
  static String byKey(String key) {
    switch (key) {
      case StringKeys.appTitle:
        return appTitle;
      case StringKeys.bootstrapMessage:
        return bootstrapMessage;
      case StringKeys.voucherStateDraft:
        return voucherStateDraft;
      case StringKeys.voucherStateConfirmed:
        return voucherStateConfirmed;
      case StringKeys.voucherStateSettled:
        return voucherStateSettled;
      default:
        return '';
    }
  }

  static const String appTitle = 'قيد';

  static const String bootstrapMessage =
      'تم تهيئة التطبيق بالعربية واتجاه من اليمين إلى اليسار.';

  static const String voucherStateDraft = 'مسودة';
  static const String voucherStateConfirmed = 'مؤكد';
  static const String voucherStateSettled = 'مسوّى';

  // Accounts — list
  static const String chartOfAccountsTitle = 'دليل الحسابات';
  static const String searchAccountsHint = 'بحث باسم الحساب…';
  static const String filterNatureAll = 'الكل';
  static const String filterNatureDebit = 'مدين';
  static const String filterNatureCredit = 'دائن';
  static const String natureDebitShort = 'مدين';
  static const String natureCreditShort = 'دائن';
  static const String accountBalanceLabel = 'الرصيد';
  static const String addAccountFab = 'حساب جديد';
  static const String retryAction = 'إعادة المحاولة';
  static const String refreshBalanceTooltip = 'تحديث الرصيد';
  static const String accountsEmpty = 'لا توجد حسابات بعد.';
  static const String accountsEmptyFiltered = 'لا نتائج مطابقة للبحث أو التصفية.';
  static const String addChildAccountTooltip = 'إضافة حساب فرعي';

  // Accounts — detail
  static const String accountDetailTitle = 'تفاصيل الحساب';
  static const String classificationLabel = 'التصنيف';
  static const String natureLabel = 'الطبيعة';
  static const String accountTypeLabel = 'النوع';
  static const String accountTypeRoot = 'جذر';
  static const String accountTypeChild = 'فرعي';
  static const String parentAccountLabel = 'الحساب الأب';
  static const String statusLabel = 'الحالة';
  static const String statusActive = 'نشط';
  static const String statusInactive = 'موقوف';
  static const String createdAtLabel = 'تاريخ الإنشاء';

  // Accounts — create
  static const String newRootAccountTitle = 'حساب جذر جديد';
  static const String newChildAccountTitle = 'حساب فرعي جديد';
  static const String accountNameLabel = 'اسم الحساب';
  static const String accountNameRequired = 'يرجى إدخال اسم الحساب.';
  static const String classificationSectionTitle = 'تصنيف الحساب الجذر';
  static const String standardClassificationTab = 'قياسي';
  static const String customClassificationTab = 'مخصص';
  static const String customClassificationNameLabel = 'اسم التصنيف المخصص';
  static const String customClassificationNameRequired = 'يرجى إدخال اسم التصنيف.';
  static const String customNatureLabel = 'طبيعة التصنيف';
  static const String saveAccount = 'حفظ';
  static const String accountCreatedSuccess = 'تم إنشاء الحساب بنجاح.';

  static const String classificationOther = 'تصنيف آخر';

  // Shell
  static const String navAccountsTab = 'الحسابات';
  static const String navVouchersTab = 'السندات';
  static const String navReportsTab = 'التقارير';
  static const String navMessagesTab = 'الرسائل';

  // Governance / activation (Phase 2)
  static const String activationSubtitle =
      'أدخل بيانات التفعيل للمتابعة. يتم التحقق من الخادم (وضع تجريبي حالياً).';
  static const String activationOrgIdLabel = 'معرّف المنشأة';
  static const String activationLicenseLabel = 'مفتاح الترخيص';
  static const String activationFieldRequired = 'هذا الحقل مطلوب.';
  static const String activationSubmit = 'تفعيل';
  static const String governanceSuspendedBanner =
      'وضع التعليق نشط: يمكنك الاطلاع فقط. عمليات الحفظ والتأكيد معطّلة مؤقتاً.';
  static const String governanceRecheckAction = 'تحقق';

  // Vouchers
  static const String pickAccountTitle = 'اختر حساباً';
  static const String voucherListTitle = 'سندات القبض والصرف';
  static const String voucherSearchHint =
      'بحث بالبيان أو الرقم أو المرجع…';
  static const String voucherFilterSheetTitle = 'تصفية السندات';
  static const String voucherFilterApply = 'تطبيق';
  static const String voucherFilterClearFields = 'مسح الحقول';
  static const String voucherFilterTypeSection = 'نوع السند';
  static const String voucherFilterTypeAny = 'الكل';
  static const String voucherFilterStateSection = 'الحالة';
  static const String voucherFilterStateAny = 'الكل';
  static const String voucherFilterDateSection = 'نطاق التاريخ';
  static const String voucherFilterDateFrom = 'من تاريخ';
  static const String voucherFilterDateTo = 'إلى تاريخ';
  static const String voucherFilterDateNotSet = 'لم يُحدَّد';
  static const String voucherFilterAccountsSection = 'الحسابات';
  static const String voucherFilterNotSelected = 'لم يُختر';
  static const String voucherFilterChipSearchPrefix = 'بحث: ';
  static const String voucherClearAllFiltersChip = 'مسح الكل';
  static const String vouchersEmpty = 'لا توجد سندات بعد. أنشئ سند قبض أو صرف.';
  static const String vouchersEmptyFiltered =
      'لا سندات مطابقة للبحث أو التصفية.';
  static const String voucherNewTitle = 'سند جديد';
  static const String voucherTypeReceipt = 'قبض';
  static const String voucherTypePayment = 'صرف';
  static const String voucherCounterpartyLabel = 'الطرف المقابل';
  static const String voucherAffectedAccountLabel = 'الحساب المتأثر';
  static const String voucherAmountLabel = 'المبلغ';
  static const String voucherDateLabel = 'تاريخ السند';
  static const String voucherDescriptionLabel = 'البيان (اختياري)';
  static const String voucherPickAffectedHint = 'اختر الحساب المتأثر (مثل النقدية)';
  static const String voucherPickCounterpartyHint = 'اختر الطرف (مثل المورد)';
  static const String voucherAmountRequired = 'يرجى إدخال مبلغ صالح أكبر من صفر.';
  static const String voucherSelectBothAccounts = 'يرجى اختيار الحسابين.';
  static const String voucherDifferentAccounts = 'لا يمكن اختيار نفس الحساب مرتين.';
  static const String voucherCreatedDraft = 'تم حفظ السند كمسودة.';
  static const String voucherDetailTitle = 'تفاصيل السند';
  static const String voucherConfirmAction = 'تأكيد';
  static const String voucherConfirmedSuccess = 'تم تأكيد السند وتسجيل القيود.';
  static const String voucherSaveDraft = 'حفظ كمسودة';
  static const String affectedAccountSection = 'الحساب المتأثر';
  static const String counterpartySection = 'الطرف المقابل';
  static const String voucherCurrencyLabel = 'عملة السند';

  // --- QR Exchange ---
  static String get qrCodeDisplayTitle => 'تبادل السند عبر QR';
  static String get qrCodeShowTooltip => 'عرض رمز الاستجابة السريعة (QR)';
  static String get qrScannerTitle => 'مسح رمز السند (QR)';
  static String get qrScannerHint => 'ضع الرمز داخل المربع';
  static String get qrCloseAction => 'إغلاق';

  // Trial balance
  static const String trialBalanceTitle = 'ميزان المراجعة';
  static const String trialBalanceColAccount = 'اسم الحساب';
  static const String trialBalanceColDebit = 'إجمالي المدين';
  static const String trialBalanceColCredit = 'إجمالي الدائن';
  static const String trialBalanceGrandTotal = 'الإجمالي';
  static const String trialBalanceBalanced =
      'متوازن — إجمالي المدين يساوي إجمالي الدائن.';
  static const String trialBalanceNotBalanced =
      'غير متوازن — يوجد فرق يجب مراجعته.';
  static const String trialBalanceImbalanceLabel = 'الفرق (مدين − دائن):';
  static const String voucherReferenceLabel = 'المرجع';
  static const String voucherNotesLabel = 'ملاحظات';

  // PDF export / share
  static const String exportSharePdfTooltip = 'تصدير ومشاركة PDF';
  static const String accountStatementExportPdfTooltip = 'تصدير كشف الحساب PDF';
  static const String exportPdfShareError = 'تعذر فتح نافذة المشاركة.';

  // Messaging / templates (Phase 3, offline intents)
  static const String notificationTemplatesTitle = 'قوالب الرسائل';
  static const String notificationPreviewTitle = 'إرسال إشعار';
  static const String notificationSelectTemplate = 'اختر القالب';
  static const String notificationMessageBody = 'نص الرسالة (يمكنك التعديل)';
  static const String notificationSendSms = 'رسالة نصية';
  static const String notificationSendWhatsApp = 'واتساب';
  static const String notificationIntentSms =
      'تم فتح تطبيق الرسائل — سجّلنا المحاولة محلياً.';
  static const String notificationIntentWa =
      'تم فتح واتساب — سجّلنا المحاولة محلياً.';
  static const String notificationNoTemplates = 'لا توجد قوالب لهذا السياق.';
  static const String templateKindReceipt = 'قبض';
  static const String templateKindPayment = 'صرف';
  static const String templateKindAccount = 'رصيد حساب';
  static const String templateEditTitle = 'تعديل القالب';
  static const String templateNameLabel = 'اسم القالب';
  static const String templateBodyLabel = 'النص (استخدم {{اسم_الحقل}})';
  static const String templateEditSave = 'حفظ';
  static const String templateEditCancel = 'إلغاء';
  static const String templateDeleteTitle = 'حذف القالب';
  static const String templateDeleteMessage = 'حذف هذا القالب نهائياً؟';
  static const String templateDeleteConfirm = 'حذف';
  static const String templateAddFab = 'قالب جديد';
  static const String templateAddTitle = 'قالب رسالة جديد';
  static const String templateKindPickerLabel = 'نوع القالب';
  static const String voucherSendMessageTooltip = 'إرسال برسالة';
  static const String accountSendMessageTooltip = 'إرسال برسالة';

  // Settings / data portability (Phase 4)
  static const String settingsTitle = 'الإعدادات';
  static const String settingsSectionBackup = 'النسخ الاحتياطي والاستعادة';
  static const String settingsBackupShareTitle = 'نسخ احتياطي (مشاركة)';
  static const String settingsBackupShareSubtitle =
      'إنشاء نسخة من قاعدة البيانات المشفّرة وعرضها في ورقة المشاركة.';
  static const String settingsBackupSaveTitle = 'حفظ النسخة في ملف';
  static const String settingsBackupSaveSubtitle =
      'اختر مساراً لحفظ الملف (متوفر على بعض المنصات).';
  static const String settingsBackupConfirmTitle = 'تأكيد النسخ الاحتياطي';
  static const String settingsBackupConfirmBody =
      'سيتم إنشاء نسخة من قاعدة بيانات قيد المشفّرة. احتفظ بالملف في مكان آمن.';
  static const String settingsProceed = 'متابعة';
  static const String settingsRestoreTitle = 'استعادة من نسخة احتياطية';
  static const String settingsRestoreSubtitle =
      'اختر ملف قاعدة بيانات صالحاً من قيد (مشفّر).';
  static const String settingsRestoreWarningTitle = 'تحذير: استبدال البيانات';
  static const String settingsRestoreWarningBody =
      'سيتم استبدال جميع البيانات الحالية بالنسخة الاحتياطية. لا يمكن التراجع عن هذا الإجراء. تأكد أن الملف صحيح قبل المتابعة.';
  static const String settingsRestoreConfirm = 'استعادة والاستبدال';
  static const String settingsRestoreDone =
      'تمت الاستعادة. يُنصح بمراجعة البيانات.';
  static const String settingsRestoreError = 'تعذر إكمال الاستعادة: ';
  static const String settingsBackupSaved = 'تم حفظ النسخة الاحتياطية.';
  static const String settingsSectionExport = 'تصدير البيانات';
  static const String settingsExportAllTitle = 'تصدير كل البيانات (Excel)';
  static const String settingsExportAllSubtitle =
      'ملف واحد يحتوي ورقتي الحسابات والسندات.';
  static const String settingsExportConfirmTitle = 'تأكيد التصدير';
  static const String settingsExportConfirmBody =
      'سيتم إنشاء ملف Excel يحتوي على حساباتك وسنداتك الحالية.';
  static const String settingsExportVouchersTitle = 'تصدير قائمة السندات (Excel)';
  static const String settingsExportStatementTitle = 'تصدير كشف حساب (Excel)';
  static const String settingsExportStatementSubtitle =
      'اختر حساباً لتصدير كشفه كاملاً.';
  static const String settingsExportStatementPickTitle = 'حساب للتصدير';
  static const String settingsSectionDraft = 'مسودات';
  static const String settingsCsvImportTitle = 'استيراد حسابات من CSV (مسودة)';
  static const String settingsCsvImportSubtitle =
      'تحليل الملف فقط — لا يُنشأ حساب بعد.';
  static const String settingsCsvPreviewTitle = 'معاينة الاستيراد';
  static const String settingsUnderstood = 'حسناً';

  static String settingsCsvPreviewBody(int rowCount) =>
      'تم تحليل $rowCount صفاً. اختر التصنيف الافتراضي ثم اضغط استيراد.';

  static const String settingsCsvDefaultClassification =
      'التصنيف الافتراضي (للصفوف بدون طبيعة واضحة)';
  static const String settingsCsvImportExecute = 'استيراد الحسابات';
  static const String settingsCsvImportConfirmTitle = 'تأكيد الاستيراد';
  static String settingsCsvImportConfirmBody(int count) =>
      'سيتم إنشاء $count حساباً جذرياً في دليل الحسابات. المتابعة؟';
  static String settingsCsvImportDone(int ok, int fail) =>
      'اكتمل الاستيراد: $ok ناجح، $fail فشل.';
  static const String settingsSectionCurrency = 'إدارة العملات';
  static const String settingsSectionSecurity = 'الأمان';
  static const String securityLockTitle = 'قفل التطبيق بعد الخلفية';
  static const String securityLockSubtitle =
      'يطلب فتح القفل بعد 5 دقائق في الخلفية.';
  static const String securitySetPinTitle = 'تعيين رمز القفل';
  static const String securitySetPinSubtitle =
      'من 4 إلى 8 أرقام. يُستخدم عند عدم توفر البصمة.';
  static const String securityBiometricTitle = 'استخدام البصمة أو الوجه';
  static const String securityPinDialogTitle = 'رمز القفل';
  static const String securityPinField = 'الرمز';
  static const String securityPinRepeat = 'تأكيد الرمز';
  static const String securityPinMismatch = 'الرمزان غير متطابقين.';
  static const String securityPinLength = 'الرمز يجب أن يكون بين 4 و 8 أرقام.';
  static const String securityNeedPinFirst =
      'عيّن رمز القفل أولاً من «تعيين رمز القفل».';
  static const String securityPinSaved = 'تم حفظ رمز القفل.';
  static const String securityPinWrong = 'رمز غير صحيح.';
  static const String lockScreenTitle = 'قيد محمي';
  static const String lockScreenSubtitle =
      'أدخل الرمز أو استخدم البصمة لفتح التطبيق.';
  static const String unlockAction = 'فتح القفل';
  static const String biometricUnlock = 'بصمة أو وجه';
  static const String securityBiometricReason = 'افتح قيد للمتابعة';

  // Auto-suggestions (offline pattern matching)
  static const String smartSuggestionsTitle = 'مقترحات ذكية';
  static const String smartSuggestionAccept = 'قبول';
  static const String smartSuggestionAmount = 'المبلغ';
  static const String smartSuggestionDate = 'التاريخ';
  static const String smartSuggestionType = 'النوع';

  static String standardClassificationLabel(String kind) {
    switch (kind) {
      case 'assets':
        return 'الأصول';
      case 'liabilities':
        return 'الالتزامات';
      case 'equity':
        return 'حقوق الملكية';
      case 'income':
        return 'الإيرادات';
      case 'expenses':
        return 'المصروفات';
      default:
        return kind;
    }
  }
}
