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
      case StringKeys.voucherStateSent:
        return voucherStateSent;
      case StringKeys.voucherStateConfirmed:
        return voucherStateConfirmed;
      case StringKeys.voucherStateSettled:
        return voucherStateSettled;
      case StringKeys.voucherJumpHeader:
        return voucherJumpHeader;
      case StringKeys.balanceSheetTitle:
        return balanceSheetTitle;
      case StringKeys.financialCenterPrefix:
        return financialCenterPrefix;
      case StringKeys.assetsLabel:
        return assetsLabel;
      case StringKeys.liabilitiesLabel:
        return liabilitiesLabel;
      case StringKeys.equityLabel:
        return equityLabel;
      case StringKeys.totalsSummaryPrefix:
        return totalsSummaryPrefix;
      case StringKeys.balancedLabel:
        return balancedLabel;
      case StringKeys.unbalancedLabel:
        return unbalancedLabel;
      case StringKeys.totalAssetsLabel:
        return totalAssetsLabel;
      case StringKeys.totalLiabilitiesLabel:
        return totalLiabilitiesLabel;
      case StringKeys.netLiabilitiesAndEquityLabel:
        return netLiabilitiesAndEquityLabel;
      case StringKeys.accountLabel:
        return accountLabel;
      default:
        return '';
    }
  }

  // Refactored UI Strings
  static const String costCenterSelectionTitle = 'اختر مركز التكلفة';
  static String costCenterDimensionsTitle(String name) => 'أبعاد $name';
  static const String costCenterCustomizeDimensions = 'تخصيص الأبعاد';
  static const String costCenterApplyDimensions = 'تطبيق الأبعاد';
  static const String voucherAffectedAccountParty = 'الحساب المتأثر (طَرَف)';
  static const String voucherPickCounterpartyHint2 =
      'اختر حساب الطرف (العميل/المورد)';
  static const String costCenterNoCentersAvailable = 'لا يوجد مراكز تكلفة .';
  static const String costCenterAllAddedAllAvailable =
      'تمت إضافة جميع مراكز التكلفة المتاحة.';
  static const String costCenterTagsLabel = 'مراكز التكلفة والأبعاد';
  static const String costCenterNoneLinked = 'لا توجد مراكز تكلفة مرتبطة.';
  static const String professionWizardRootError =
      'خطأ: لم يتم العثور على حساب الإيرادات الجذر.';
  static const String professionWizardSuccess =
      'تم تسجيل المهنة كمصدر دخل بنجاح.';
  static const String professionAccountNameRequired = 'يرجى إدخال اسم الحساب';
  static const String professionNameRequired = 'يرجى إدخال اسم المهنة';
  static const String defaultCostCentersTitle = 'مراكز التكلفة الافتراضية';
  static const String professionAddCostCenter = 'إضافة مركز تكلفة للمهنة';
  static const String internalVoucherFundError =
      'خطأ: لم يتم العثور على حساب الصندوق الرئيسي.';
  static const String internalVoucherCategoryRequired =
      'يرجى اختيار حساب المصروف أو الإيراد أولاً.';
  static const String internalVoucherSuccess =
      'تم تسجيل المعاملة الداخلية بنجاح.';
  static const String internalVoucherPickExpense =
      'اختر حساب المصروف أو التجارة';
  static const String internalVoucherPickRevenue = 'اختر مصدر الدخل أو الأصل';
  static const String actionRecordTransaction = 'تسجيل العملية';
  static const String suggestionRecurring = 'متكرر';
  static const String suggestionClaim = 'مطالبة';
  static const String incomeStreamTracker = 'سجل التتبع';
  static const String incomeStreamExpense = 'تصنيف مصروفات';
  static const String incomeStreamAsset = 'أصل استثماري ذو عائد';
  static const String incomeStreamPossession = 'ممتلكات شخصية';
  static const String incomeStreamProfession = 'مصدر دخل مهني';
  static const String exportPdfStatement = 'تصدير كشف حساب PDF';
  static const String exportExcelStatement = 'تصدير كشف حساب Excel';
  static const String incomeStreamNoData =
      'لا توجد بيانات مالية مسجلة حتى الآن.';
  static const String incomeStreamLoadError =
      'حدث خطأ أثناء تحميل السجل المالي.';
  static const String incomeStreamPurchasePrice = 'قيمة الاستحواذ: ';
  static const String incomeStreamPerHour = '/ساعة';
  static const String incomeStreamDatePrefix = 'تاريخ: ';
  static const String ledgerMovement = 'حركة السجل (Ledger)';
  static const String filterApplied = 'تمت التصفية';
  static const String filterLedger = 'تصفية السجل';
  static const String financialBalancePerformance = 'أداء الرصيد المالي';
  static String costCenterRemoveConfirmBody(String name) =>
      'إزالة "$name" من المراكز الافتراضية؟';
  static const String costCenterRemoveError = 'تعذر إزالة مركز التكلفة.';
  static const String defaultCostCentersDesc =
      'تُضاف هذه المراكز تلقائياً عند اختيار هذا الحساب في سند صرف أو قبض جديد.';
  static const String defaultCostCentersEmpty =
      'لا توجد مراكز تكلفة افتراضية محددة.';
  static const String costCenterAddCenter = 'إضافة مركز';
  static const String modelLabel = 'الموديل';
  static const String serialNumberLabel = 'الرقم التسلسلي';
  static const String serialNumberOrPlateLabel = 'الرقم التسلسلي / اللوحة';
  static const String purchaseDateLabel = 'تاريخ الشراء';
  static const String statusActiveEn = 'نشط (Active)';
  static const String statusInactiveEn = 'موقف (Inactive)';
  static const String filterLedgerTitle = 'تصفية السجل المالي';
  static const String financialMovementType = 'نوع الحركة المالية';
  static const String internalVoucherReceiptLabel = 'إيراد / توريد';
  static const String internalVoucherPaymentLabel = 'مصروف / صرف نقدية';
  static const String assetsEmptyList = 'لا تملك أي أصول مسجلة حالياً.';

  static const String statusRejected = 'مرفوض';
  static const String actionDelete = 'حذف';
  static const String confirmDeletionTitle = 'تأكيد الحذف';
  static const String costCenterSaveError = 'تعذر حفظ مركز التكلفة';
  static const String actionAttachImages = 'إرفاق صور';
  static const String actionAdd = 'إضافة';

  static const String appTitle = 'قيد';

  static const String bootstrapMessage =
      'تم تهيئة التطبيق بالعربية واتجاه من اليمين إلى اليسار.';
  static const String voucherStateSent = 'مرسل مجهول';
  static const String voucherStateConfirmed = 'مؤكد (على الحساب)';
  static const String voucherStateSettled = 'مسوى (نقد)';
  static const String tripartiteContingentBadge = 'ذمم مشروطة';
  static const String voucherReplyHeader = 'رد على سنده رقم #...';
  static const String voucherJumpHeader =
      'يوجد إصدار أحدث لهذا السند. اضغط للانتقال.';

  static const String voucherStateDraft = 'مسودة';
  static const String voucherStateWithdrawn = 'مسحوب';

  // Accounts — list
  static const String chartOfAccountsTitle = 'دليل الحسابات الأساسية';
  static const String searchAccountsHint = 'بحث باسم الحساب…';
  static const String filterNatureAll = 'الكل';
  static const String filterNatureDebit = 'مدين (عليك)';
  static const String filterNatureCredit = 'دائن (لك)';
  static const String natureDebitShort = 'مدين (عليك)';
  static const String natureCreditShort = 'دائن (لك)';
  static const String accountBalanceLabel = 'الرصيد';
  static const String addAccountFab = 'حساب جديد';
  static const String retryAction = 'إعادة المحاولة';
  static const String refreshBalanceTooltip = 'تحديث الرصيد';
  static const String accountsEmpty = 'لا توجد حسابات بعد.';
  static const String accountsEmptyFiltered =
      'لا نتائج مطابقة للبحث أو التصفية.';
  static const String addChildAccountTooltip = 'إضافة حساب فرعي';

  // Accounts — detail
  static const String accountDetailTitle = 'تفاصيل الحساب';
  static const String classificationLabel = 'التصنيف';
  static const String natureLabel = 'الطبيعة';
  static const String accountTypeLabel = 'النوع';
  static const String accountTypeRoot = 'جذر';
  static const String accountTypeChild = 'فرع';
  static const String parentAccountLabel = 'الحساب الأب';
  static const String statusLabel = 'الحالة';
  static const String statusActive = 'نشط';
  static const String statusInactive = 'موقوف';
  static const String archiveAccountAction = 'أرشفة الحساب';
  static const String archiveAccountWarningText =
      'هل أنت متأكد من أرشفة هذا الحساب؟\nلا يمكن أرشفة الحساب إلا إذا كان رصيده صفراً في جميع العملات، وسيتم إخفاؤه من جميع القوائم والتقارير.';
  static const String archiveAccountConfirm = 'تأكيد الأرشفة';
  static const String archiveAccountSuccess = 'تم أرشفة الحساب بنجاح';

  // Archived Accounts
  static const String archivedAccountsTitle = 'الحسابات المؤرشفة';
  static const String archivedAccountsEmpty = 'لا توجد حسابات مؤرشفة حالياً';
  static const String restoreAccountAction = 'استعادة';
  static const String restoreAccountTitle = 'استعادة الحساب';
  static String restoreAccountWarning(String accountName) =>
      'هل أنت متأكد من رغبتك في استعادة الحساب "$accountName"؟ سيظهر الحساب في جميع القوائم والتقارير مجدداً.';
  static const String restoreAccountConfirm = 'تأكيد الاستعادة';
  static const String restoreAccountSuccess = 'تمت استعادة الحساب بنجاح';

  // Accounts — create
  static const String newRootAccountTitle = 'حساب جذر جديد';
  static const String newChildAccountTitle = 'حساب فرعي جديد';
  static const String accountNameLabel = 'اسم الحساب';
  static const String accountNameRequired = 'يرجى إدخال اسم الحساب.';
  static const String classificationSectionTitle = 'تصنيف الحساب الجذر';
  static const String standardClassificationTab = 'قياسي';
  static const String customClassificationTab = 'مخصص';
  static const String customClassificationNameLabel = 'اسم التصنيف المخصص';
  static const String customClassificationNameRequired =
      'يرجى إدخال اسم التصنيف.';
  static const String customNatureLabel = 'طبيعة التصنيف';
  static const String saveAccount = 'حفظ';
  static const String accountCreatedSuccess = 'تم إنشاء الحساب بنجاح.';
  static const String partyDetailsSection = 'بيانات الطرف (اختياري)';
  static const String partyPhoneLabel = 'رقم الهاتف';
  static const String partyWhatsappLabel = 'رقم الواتساب';
  static const String partyBankInfoLabel = 'بيانات الحساب البنكي (مثل الكريمي)';
  static const String partyTypeLabel = 'نوع الطرف (صديق، مورد، الخ)';
  static const String actionCall = 'اتصال';
  static const String actionWhatsApp = 'واتساب';
  static const String actionCopyBank = 'نسخ الحساب';
  static const String bankInfoCopied = 'تم نسخ بيانات الحساب البنكي.';
  static const String shareAsTextTooltip = 'مشاركة كنص';
  static const String shareAsImageTooltip = 'مشاركة كصورة';

  static const String classificationOther = 'تصنيف آخر';

  // Shell
  static const String navVouchersTab = 'السندات';
  static const String navTripartiteTab = 'التحويلات';
  static const String navAccountsTab = 'الحسابات';
  static const String navReportsTab = 'التقارير';
  static const String navMessagesTab = 'الرسائل';
  static const String navManagementTab = 'الإدارة';

  // Management Unit
  static const String managementTitle = 'الإدارة المالية الشخصية';
  static const String internalVouchersTitle = 'سندات المصروفات والإيرادات';
  static const String addInternalVoucherFab = 'سند جديد';
  static const String internalVoucherTypeReceipt = 'إيراد شخصي';
  static const String internalVoucherTypePayment = 'مصروف شخصي';
  static const String internalVoucherFundAccount = 'الصندوق';
  static const String managementTabFinancialRecords = 'السجل المالي';
  static const String managementTabAssets = 'الأصول والممتلكات';
  static const String managementTabPersonalFlowAccounts =
      'حسابات التدفقات الشخصية';
  static const String managementTabFundFlows = 'تدفقات الصندوق';
  static const String managementTabRevenues = 'إيرادات الصندوق';
  static const String managementTabExpenses = 'مصاريف الصندوق';
  static const String managementAddAssetFab = 'إضافة أصل جديد';
  static const String managementAddRevenueFab = 'تسجيل إيراد داخلي';
  static const String managementAddExpenseFab = 'تسجيل مصروف داخلي';
  static const String managementSearchHint = 'ابحث في السندات الداخلية...';
  static const String managementLabelExpenses = 'المصروفات';
  static const String managementLabelRevenues = 'الإيرادات';
  static const String managementManageAccruals = 'إدارة الالتزامات الدورية';
  static const String managementFilterAll = 'الكل';
  static const String managementAddFlowFab = 'إضافة حركة (دخل/مصرف)';
  static const String managementSearchVouchersHint = 'ابحث في السجلات...';
  static const String managementAssetsEmpty = 'لا توجد أصول مسجلة حالياً.';
  static const String managementExpensesEmpty =
      'لا توجد قنوات صرف مسجلة حالياً.';
  static const String managementTabOutflowSources = 'قنوات الإنفاق';
  static const String managementAssetValueLabel = 'قيمة الأصل الاستراتيجية';
  static const String managementAssetYieldLabel = 'العائد الناتج';
  static const String managementSearchNoResults = 'لا توجد نتائج لبحثك';
  static const String managementInvestmentAssets =
      'الأصول الاستثمارية (المدرة)';
  static const String managementPersonalPossessions =
      'المقتنيات الشخصية (الثابتة)';
  static const String assetWizardInvestmentTitle = 'إضافة أصل استثماري';
  static const String assetWizardPossessionTitle = 'إضافة مقتنى شخصي';
  static const String assetWizardIncomeSourceLabel = 'هل يدر دخلاً دورياً؟';
  static const String managementAssetLinkRevenue =
      'الأصل/المشروع المرتبط (مصدر الدخل)';
  static const String managementAssetLinkExpense =
      'مركز التكلفة / المصلحة (جهة الصرف)';

  static const String expenseWizardTitle = 'إضافة تصنيف مصروفات';
  static const String expenseWizardRootError =
      'خطأ: لم يتم العثور على حساب المصروفات الجذر.';
  static const String expenseWizardSuccess = 'تم إضافة تصنيف المصروفات بنجاح.';
  static const String expenseWizardHeaderTitle = 'تصنيف مصروف جديد';
  static const String expenseWizardHeaderDesc =
      'تصنيفات المصروفات تعمل كأوعية لتجميع وتتبع نفقاتك ضمن نفس السياق (مثلًا: صيانة سيارة، فواتير إلكترونية).';
  static const String expenseWizardNameLabel = 'اسم تصنيف المصروفات';
  static const String expenseWizardNameHint =
      'مثال: اشتراكات شهرية، وقود السيارة، مقاضي المنزل...';
  static const String expenseWizardNameRequired = 'يرجى إدخال اسم التصنيف';
  static const String expenseWizardSubmit = 'إضافة التصنيف وتحليله';

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
  static const String governancePaymentInstruction =
      'للمتابعة وتفعيل اشتراكك، يرجى سداد الرسوم المطلوبة إلى الحساب التالي:';
  static const String governanceOwnerAccountLabel = 'حساب مدير التطبيق (سداد)';
  static const String governanceContactAdmin =
      'بعد السداد، يرجى مشاركة صورة الإيصال مع الدعم الفني لتفعيل حسابك.';

  // Vouchers
  static const String pickAccountTitle = 'اختر حساباً';
  static const String voucherListTitle = 'سندات القيد';
  static const String voucherSearchHint = 'بحث بالبيان أو الرقم أو المرجع…';
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
  static const String voucherPickAffectedHint =
      'اختر الحساب المتأثر (مثل النقدية)';
  static const String voucherPickCounterpartyHint = 'اختر الطرف (مثل المورد)';
  static const String voucherAmountRequired =
      'يرجى إدخال مبلغ صالح أكبر من صفر.';
  static const String voucherSelectBothAccounts = 'يرجى اختيار الحسابين.';
  static const String voucherDifferentAccounts =
      'لا يمكن اختيار نفس الحساب مرتين.';
  static const String voucherCreatedDraft = 'تم حفظ السند كمسودة.';
  static const String voucherDetailTitle = 'تفاصيل السند';
  static const String voucherConfirmAction = 'تأكيد';
  static const String voucherConfirmedSuccess = 'تم تأكيد السند وتسجيل القيود.';
  static const String statementChatAccept = 'قبول';
  static const String statementChatReject = 'رفض';
  static const String statementChatResubmit = 'إعادة العرض';
  static const String voucherSaveDraft = 'حفظ كمسودة';
  static const String affectedAccountSection = 'الحساب المتأثر';
  static const String counterpartySection = 'الطرف المقابل';
  static const String voucherCurrencyLabel = 'عملة السند';
  static const String voucherAcceptedSuccess = 'تم الموافقة على السند بنجاح';
  static const String voucherRejectedSuccess = 'تم رفض السند بنجاح';
  static const String voucherWithdrawalSuccess = 'تم سحب السند بنجاح';
  static const String voucherDeleteOrWithdraw = 'حذف أو سحب السند';
  static const String voucherRedirectToOthers = 'تحويله لطرف آخر';
  static const String voucherEditAction = 'تعديل السند';
  static const String actionDetails = 'تفاصيل';
  static const String actionCopy = 'نسخ';
  static const String actionShare = 'مشاركة';
  static const String voucherAttachImages = 'إرفاق صور';
  static const String voucherAddCollateral = 'إضافة رهن';
  static const String voucherConfirmAndSend = 'تأكيد وإرسال';
  static const String warningImportant = 'تنبيه هام';
  static const String voucherEditDateOrPartyWarning =
      'لقد قمت بتغيير الطرف (العميل/المورد) أو التاريخ.\n\nسيتم سحب السند من الطرف السابق وإضافته كقيد جديد.\nهل تود المتابعة؟';
  static const String actionProceedAndConfirm = 'متابعة والتأكيد';
  static const String voucherAffectedAccountPaymentTitle = 'صرف من حساب';
  static const String voucherAffectedAccountReceiptTitle = 'قبض إلى حساب';
  static const String voucherAffectedAccountHint =
      'اختر الحساب (الصندوق/المصروفات)';
  static const String voucherCollateralValuePrefix = 'القيمة: ';
  static const String voucherConfirmedAndSentSuccess =
      'تم تأكيد السند وإرساله للمزامنة';

  // --- QR Exchange ---
  static String get qrCodeDisplayTitle => 'تبادل السند عبر QR';
  static String get qrCodeShowTooltip => 'عرض رمز الاستجابة السريعة (QR)';
  static String get qrScannerTitle => 'مسح رمز السند (QR)';
  static String get qrScannerHint => 'ضع الرمز داخل المربع';
  static String get qrCloseAction => 'إغلاق';

  static String get permissionCameraMissingTitle => 'صلاحية الكاميرا مفقودة';
  static String get permissionCameraMissingBodyQr =>
      'نحتاج للوصول إلى الكاميرا لقراءة رمز الاستجابة السريعة (QR Code). يرجى السماح بذلك من الإعدادات.';
  static String get actionCancel => 'إلغاء';
  static String get actionOpenSettings => 'فتح الإعدادات';

  // --- Identity QR Exchange (§3) ---
  static String get identityQrShowTitle => 'هويتي الرقمية (QR)';
  static String get identityQrShowSubtitle =>
      'اعرض الرمز للآخرين لإضافتك كطرف مقابل آمن';
  static String get identityQrScanTitle => 'مسح هوية الطرف (QR)';
  static String get identityQrScanHint =>
      'امسح رمز "هويتي الرقمية" الخاص بالطرف الآخر لإضافته تلقائياً';
  static String get identityQrScanSuccess => 'تم التعرف على هوية الطرف بنجاح.';
  static String get identityQrScanInvalid =>
      'رمز الهوية غير صالح أو غير تابع لتطبيق قيد.';

  // Trial balance
  static const String trialBalanceTitle = 'ميزان المراجعة';
  static const String trialBalanceColAccount = 'اسم الحساب';
  static const String trialBalanceColDebit = 'إجمالي المدين (لك)';
  static const String trialBalanceColCredit = 'إجمالي الدائن (عليك)';
  static const String trialBalanceGrandTotal = 'الإجمالي';
  static const String trialBalanceBalanced =
      'متوازن — إجمالي المدين يساوي إجمالي الدائن';
  static const String trialBalanceNotBalanced =
      'غير متوازن — يوجد فرق يجب مراجعته.';
  static const String trialBalanceImbalanceLabel = 'الفرق (مدين − دائن):';
  static const String trialBalanceEmpty =
      'ميزان المراجعة فارغ — لا توجد أي عمليات مالية مسجلة بعد.';
  static const String voucherReferenceLabel = 'المرجع';
  static const String voucherNotesLabel = 'ملاحظات';

  // Balance Sheet
  static const String balanceSheetTitle = 'الميزانية العمومية';
  static const String financialCenterPrefix = 'المركز المالي — ';
  static const String assetsLabel = 'الأصول';
  static const String liabilitiesLabel = 'الخصوم';
  static const String equityLabel = 'حقوق الملكية';
  static const String totalsSummaryPrefix = 'ملخص الإجماليات — ';
  static const String balancedLabel = 'متوازن ✓';
  static const String unbalancedLabel = 'غير متوازن';
  static const String totalAssetsLabel = 'إجمالي الأصول';
  static const String totalLiabilitiesLabel = 'إجمالي الخصوم';
  static const String netLiabilitiesAndEquityLabel = 'صافي الخصوم والملكية';
  static const String accountLabel = 'الحساب';
  static const String currencyLabel = 'العملة';

  // PDF export / share
  static const String exportSharePdfTooltip = 'تصدير ومشاركة PDF';
  static const String accountStatementExportPdfTooltip = 'تصدير كشف الحساب PDF';
  static const String exportPdfShareError = 'تعذر فتح نافذة المشاركة.';

  // Messaging / templates (Phase 3, offline intents)
  static const String notificationTemplatesTitle = 'قوالب الرسائل';
  static const String messagingInboxTab = 'البريد الوارد';
  static const String messagingTemplatesTab = 'القوالب';
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
  static const String settingsExportVouchersTitle =
      'تصدير قائمة السندات (Excel)';
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

  // Phase 7 — Security vault overlay strings
  static const String vaultPendingTitle = 'مرحباً بك في قيد';
  static const String vaultPendingBody =
      'هذا الجهاز غير مفعّل بعد. أدخل بيانات حسابك للمتابعة وربط الترخيص بهذا الجهاز.';
  static const String vaultTrialExpiredTitle = 'انتهت الفترة التجريبية';
  static const String vaultTrialExpiredBody =
      'لقد انتهت فترة الـ 30 يوماً التجريبية. يرجى التواصل مع فريق الدعم للحصول على ترخيص كامل.';
  static const String vaultRevokedTitle = 'تم إلغاء الترخيص';
  static const String vaultRevokedBody =
      'تم إلغاء ترخيص هذا الجهاز من قِبَل المسؤول. تم مسح بيانات الدخول تلقائياً. يرجى التواصل مع الدعم.';
  static const String vaultDeviceUnboundTitle = 'جهاز غير مصرّح';
  static const String vaultDeviceUnboundBody =
      'تم تفعيل هذا الترخيص على جهاز مختلف. لا يمكن تشغيل قيد على أكثر من جهاز واحد في آنٍ واحد.';
  static const String vaultClockTamperedTitle = 'تلاعب بالساعة مكتشَف';
  static const String vaultClockTamperedBody =
      'تم الكشف عن تلاعب في ساعة الجهاز. تم قفل التطبيق حماية للبيانات المالية. أعد ضبط التاريخ والوقت الصحيح ثم أعد تشغيل التطبيق.';
  static const String vaultContactSupport =
      'للدعم والاستفسار: support@qayd.app';
  static const String vaultTrialDaysRemaining = 'يوم متبقٍ في الفترة التجريبية';
  static const String vaultEmailHint = 'البريد الإلكتروني';
  static const String vaultPasswordHint = 'كلمة المرور';
  static const String vaultActivateAction = 'تفعيل الجهاز';

  // Auto-suggestions (offline pattern matching)
  static const String smartSuggestionsTitle = 'مقترحات ذكية';
  static const String smartSuggestionAccept = 'قبول';
  static const String smartSuggestionAmount = 'المبلغ';
  static const String smartSuggestionDate = 'التاريخ';
  static const String smartSuggestionType = 'النوع';

  // ── Auth Pages (Phase 7) ─────────────────────────────────────────────────
  static const String loginTitle = 'تسجيل الدخول';
  static const String loginSubtitle = 'أدخل بيانات حسابك للمتابعة';
  static const String loginAction = 'دخول';
  static const String forgotPassword = 'نسيت كلمة المرور؟';
  static const String noAccount = 'ليس لديك حساب؟';
  static const String createAccount = 'إنشاء حساب جديد';
  static const String registerTitle = 'إنشاء حساب';
  static const String registerSubtitle = 'هذا الحساب للمديرين المعتمدين فقط';
  static const String registerAction = 'إنشاء الحساب';
  static const String nameHint = 'الاسم الكامل';
  static const String confirmPasswordHint = 'تأكيد كلمة المرور';
  static const String passwordMismatch = 'كلمتا المرور غير متطابقتين';
  static const String invalidEmail = 'البريد الإلكتروني غير صالح';
  static const String passwordResetTitle = 'استعادة كلمة المرور';
  static const String passwordResetSubtitle =
      'أدخل بريدك الإلكتروني لإرسال رابط الاستعادة';
  static const String passwordResetEmailSent =
      'تم إرسال رابط الاستعادة إلى بريدك الإلكتروني.';
  static const String passwordResetAction = 'إرسال رابط الاستعادة';
  static const String passwordResetNewPassword = 'كلمة المرور الجديدة';
  static const String passwordResetTokenHint = 'رمز التحقق';
  static const String passwordResetConfirmAction = 'تعيين كلمة المرور الجديدة';
  static const String passwordResetSuccess = 'تم تغيير كلمة المرور بنجاح';
  static const String backToLogin = 'العودة إلى تسجيل الدخول';
  static const String passwordResetError = 'تعذر إرسال الطلب. تحقق من الاتصال.';
  static const String passwordChangeError =
      'تعذر تغيير كلمة المرور. حاول مرة أخرى.';
  static const String passwordTooShort =
      'كلمة المرور يجب أن تكون 8 أحرف على الأقل.';
  static const String agreeToTermsRequired =
      'يجب الموافقة على شروط الاستخدام وسياسة الخصوصية';
  static const String serverConnectionError =
      'تعذر الاتصال بالخادم. تحقق من الاتصال وحاول مجدداً.';
  static const String termsOfUseLabel = 'شروط الاستخدام';
  static const String privacyPolicyLabel = 'سياسة الخصوصية';
  static const String iAgreeTo = 'أوافق على ';
  static const String andLabel = ' و';
  static const String loadingLabel = 'جاري التحميل...';
  static const String termsLoadingError =
      'تعذر تحميل شروط الاستخدام. يرجى المحاولة لاحقاً.';
  static const String privacyLoadingError =
      'تعذر تحميل سياسة الخصوصية. يرجى المحاولة لاحقاً.';
  static const String noTermsFound = 'لا يوجد شروط استخدام حالياً.';
  static const String noPrivacyFound = 'لا يوجد سياسة خصوصية حالياً.';
  static const String privacyTermsHeader = 'سياسة الخصوصية وشروط الاستخدام';

  // Email Verification
  static const String verificationTitle = 'تحقق من بريدك';
  static const String verificationSubtitle = 'أرسلنا رمز التحقق إلى';
  static const String verifyAction = 'تحقق الآن';
  static const String resendPrompt = 'لم يصلك الرمز؟ ';
  static const String resendTimerPrefix = 'إعادة الإرسال خلال ';
  static const String resendTimerSuffix = ' ثانية';
  static const String resendAction = 'إعادة إرسال الرمز';
  static const String resending = 'جاري الإرسال...';
  static const String returnToLogin = 'العودة لتسجيل الدخول';
  static const String otpVerifyError = 'رمز التحقق غير صحيح أو منتهي الصلاحية.';
  static const String otpSendError = 'تعذر إرسال الرمز. حاول مجدداً.';

  // Password Reset Methods
  static const String verificationMethodSelectorTitle = 'طريقة التحقق';
  static const String verificationMethodEmailTitle = 'عبر البريد الإلكتروني';
  static const String verificationMethodEmailSubtitle =
      'إرسال رابط استعادة لبريدك المسجل';
  static const String verificationMethodPhoneTitle = 'عبر رقم الهاتف';
  static const String verificationMethodPhoneSubtitle =
      'قريباً: إرسال رمز SMS لهاتفك';
  static const String comingSoonBadge = 'قريباً';

  static String standardClassificationLabel(String kind) {
    switch (kind) {
      case 'liquidAssets':
        return 'نقدية وسيولة';
      case 'receivables':
        return 'حقوق ومستحقات';
      case 'payables':
        return 'التزامات وديون';
      case 'settlements':
        return 'تسويات مالية وشخصية';
      case 'personalExpenses':
        return 'مصروفات واستهلاك';
      case 'personalRevenues':
        return 'إيرادات ومكاسب';
      case 'clearingRemittances':
        return 'مقاصة الحوالات';
      case 'remittanceFees':
        return 'رسوم الحوالات';
      case 'fixedDepreciableAssets':
        return 'أصول ثابتة (مهلكة)';
      case 'fixedProfitableAssets':
        return 'أصول ثابتة (ربحية)';
      default:
        return kind;
    }
  }

  // ── Cryptographic Identity (Phase 10) ──────────────────────────────────
  static const String seedSetupTitle = 'إعداد الهوية الرقمية';
  static const String seedSetupBody =
      'تم إنشاء عبارة الاسترداد الخاصة بك. احتفظ بها في مكان آمن — هي الطريقة الوحيدة لاستعادة هويتك الرقمية.';
  static const String seedBackupWarning =
      'تحذير: فقدان هذه العبارة يعني فقدان القدرة على توقيع الإيصالات بهذا المفتاح.';
  static const String seedBackupConfirmTitle = 'تأكيد النسخ الاحتياطي';
  static const String seedBackupConfirmBody =
      'اكتب الكلمات التالية للتأكد من حفظك لعبارة الاسترداد.';
  static const String seedBackupConfirmed = 'تم تأكيد النسخ الاحتياطي بنجاح.';
  static const String seedBackupConfirmAction = 'لقد قمت بحفظ الكلمات بأمان';
  static const String seedBackupSkipAction = 'المتابعة لاحقاً (غير مستحسن)';

  static const String seedRecoveryTitle = 'استعادة الهوية الرقمية';
  static const String seedRecoveryBody =
      'أدخل عبارة الاسترداد المكونة من 24 كلمة لاستعادة مفتاح التوقيع.';
  static const String seedRecoveryAction = 'استعادة المفتاح';
  static const String seedRecoverySuccess = 'تم استعادة الهوية الرقمية بنجاح.';
  static const String seedRecoveryInvalid = 'عبارة الاسترداد غير صالحة.';
  static const String seedWordLabel = 'الكلمة';
  static const String identitySettingsSection = 'الهوية الرقمية';
  static const String identityPublicKeyLabel = 'المفتاح العام';
  static const String identityKeyGenerationLabel = 'جيل المفتاح';
  static const String identityBackupStatus = 'حالة النسخ الاحتياطي';
  static const String identityBackupDone = 'تم النسخ الاحتياطي';
  static const String identityBackupPending = 'لم يتم النسخ الاحتياطي بعد';
  static const String identityNotSetup = 'لم يتم إعداد الهوية الرقمية';
  static const String identitySetupAction = 'إعداد الهوية';
  static const String identityViewSeed = 'عرض عبارة الاسترداد';
  static const String identityViewSeedSubtitle =
      'اعرض كلمات الاسترداد الـ 24 لحفظها أو مشاركتها بشكل آمن.';
  static const String identityViewSeedWarningTitle = 'تحذير أمني';
  static const String identityViewSeedWarningBody =
      'ستظهر عبارة الاسترداد الخاصة بك. تأكد من أنك في مكان خاص. '
      'لا تشاركها مع أي شخص لا تثق به تماماً — من يمتلكها يمتلك هويتك الرقمية.';
  static const String identitySeedDialogBody =
      'هذه هي عبارة الاسترداد المكونة من 24 كلمة. احتفظ بها في مكان آمن.';
  static const String identitySeedWarning =
      'لا تشارك هذه الكلمات مع أي شخص. فقدانها يعني فقدان القدرة على التوقيع الرقمي.';
  static const String identitySeedCopy = 'نسخ';
  static const String identitySeedShare = 'مشاركة';
  static const String identitySeedCopied = 'تم نسخ عبارة الاسترداد.';
  static const String identityShareSeedSubject =
      'عبارة استرداد قيد — سري للغاية';
  static const String identityPublicKeyCopy = 'نسخ المفتاح العام';
  static const String identityPublicKeyCopied = 'تم نسخ المفتاح العام.';
  static const String identityRecoveryRequiredTitle = 'هوية مسجلة سابقاً';
  static const String identityRecoveryRequiredBody =
      'وجدنا هوية رقمية مسجلة مسبقاً لهذا الحساب. للمتابعة، يجب إدخال المفتاح الأساسي (عبارة الـ 24 كلمة) لاسترداد هويتك وتوقيع العمليات.';
  static const String identityRecoveryBypassWarning =
      'تحذير: تجاوز هذه الخطوة سيعطل قدرتك على التعامل مع السندات الموقعة بهويتك السابقة.';
  static const String identityRecoveryBypassAction = 'تجاوز (غير مستحسن)';
  static const String identityRecoveryEnterKeyAction = 'أدخل المفتاح الأساسي';
  static const String identityRecoveryHint =
      'المفتاح الأساسي هو عبارة عن 24 كلمة قمت بحفظها عند إنشاء هويتك لأول مرة.';
  static const String identityRecoveryInputRequired =
      'الرجاء إدخال عبارة الاسترداد';

  // ── Auto backup ─────────────────────────────────────────────────────────
  static const String settingsSectionAutoBackup = 'النسخ الاحتياطي التلقائي';
  static const String autoBackupToggleTitle = 'نسخ احتياطي يومي تلقائي';
  static const String autoBackupToggleSubtitle =
      'يحفظ نسخة يومية من البيانات تلقائياً مثل واتساب — يحتفظ بآخر 7 نسخ.';
  static const String autoBackupLastBackupLabel = 'آخر نسخة احتياطية';
  static const String autoBackupNever = 'لم يتم النسخ بعد';
  static const String autoBackupRunNow = 'نسخ الآن';
  static const String autoBackupRunNowSuccess =
      'تم إنشاء النسخة الاحتياطية بنجاح.';
  static const String autoBackupSaveToDevice = 'حفظ في الجهاز';
  static const String autoBackupSavedExternal =
      'تم حفظ النسخة الاحتياطية في وحدة التخزين الخارجية.';

  // Transfer Fees Settings
  static const String transferFeeToggleTitle = 'تفعيل التحويلات والرسوم';
  static const String transferFeeToggleSubtitle =
      'تفعيل ميزة التحويل الوسيط وتحديد رسوم تلقائية لها.';
  static const String transferFeeAmountLabel = 'مبلغ الرسوم';
  static const String transferFeeErrorInvalidAmount =
      'يرجى إدخال مبلغ صحيح للرسوم';
  static const String transferFeeSaveSuccess = 'تم حفظ إعدادات الرسوم';
  static const String transferFeeActionSave = 'حفظ التغييرات';
  static const String transferFeeActionEdit = 'تعديل مبلغ الرسوم';

  static const String tripartiteDisabledError =
      'خيار التحويل عبر مقاصة الحوالات غير مفعل من الإعدادات.';
  static const String tripartiteGoToSettings = 'الإعدادات';
  static const String tripartiteDisabledDialogTitle = 'خيار التحويل الوسيط غير مفعل';
  static const String tripartiteDisabledDialogContent =
      'يجب تفعيل خيار التحويل عبر مقاصة الحوالات من الإعدادات لتتمكن من استخدام هذا النوع من التحويلات.';

  // ── Google Drive backup ─────────────────────────────────────────────────
  static const String settingsSectionDriveBackup = 'النسخ الاحتياطي على Drive';
  static const String driveBackupSuspendedNotice =
      'هذه الخدمة موقوفة مؤقتاً. سيتم تفعيل النسخ الاحتياطي على Google Drive في إصدار قادم.';
  static const String driveBackupToggleTitle = 'النسخ على Google Drive';
  static const String driveBackupToggleSubtitle =
      'نسخ تلقائي يومي إلى Google Drive — مثل واتساب بالضبط.';
  static const String driveBackupAccountLabel = 'حساب Google';
  static const String driveBackupNoAccount = 'لم يتم تسجيل الدخول';
  static const String driveBackupFrequencyLabel = 'تكرار النسخ';
  static const String driveBackupFrequencyDaily = 'يومياً';
  static const String driveBackupRestoreAction = 'استعادة من Drive';
  static const String driveBackupSignOutTitle = 'تسجيل الخروج';
  static const String driveBackupSignOutBody =
      'هل أنت متأكد من أنك تريد تسجيل الخروج؟ سيتم إيقاف النسخ الاحتياطي التلقائي على Google Drive.';
  static const String driveBackupUploadSuccess =
      'تم رفع النسخة الاحتياطية إلى Google Drive بنجاح.';
  static const String driveBackupRestoreTitle = 'استعادة من Google Drive';
  static const String driveBackupRestoreBody =
      'سيتم استبدال جميع البيانات الحالية بالنسخة الاحتياطية المرفوعة. لا يمكن التراجع عن هذا الإجراء. المتابعة؟';
  static const String driveBackupLastDate = 'تاريخ الملف';
  static const String driveBackupSignOut = 'خروج';
  static const String driveBackupSignIn = 'ربط حساب';
  static const String driveBackupNow = 'نسخ الآن';

  // Agreement status labels
  static const String agreementUnderRequest = 'بانتظار الموافقة';
  static const String agreementAccepted = 'مقبول وموقّع';
  static const String agreementRejected = 'مرفوض';
  static const String agreementUnverified = 'غير مؤكد';

  // Receipt sharing
  static const String shareReceiptTitle = 'مشاركة الإيصال';
  static const String shareAsQr = 'رمز QR';
  static const String shareAsSms = 'رسالة نصية SMS';
  static const String shareViaWhatsApp = 'واتساب';
  static const String shareAsPdf = 'مستند PDF';
  static const String shareAsImage = 'صورة';
  static const String receiptSignedBy = 'موقّع بواسطة';
  static const String receiptVerifiedLabel = 'تم التحقق من التوقيع الرقمي';
  static const String receiptSignatureSection = 'التوقيع الرقمي';
  static const String receiptPublicKeyLabel = 'مفتاح الموقّع';

  // ── Tripartite Intermediary Transfer ────────────────────────────────────
  static const String tripartiteToggleLabel = 'تحويل وسيط';
  static const String tripartiteRequestFunds = 'طلب حوالة';
  static const String tripartiteMediatorLabel = 'وسيط';
  static const String tripartiteToggleSubtitle =
      'تحويل مبلغ بين طرفين عبر حسابك كوسيط';
  static const String tripartiteSourceLabel = 'الحساب المُرْسِل (مَدين)';
  static const String tripartiteDestinationLabel = 'الحساب المُلْتزم (دائن)';
  static const String tripartitePickSourceHint = 'اختر الطرف المُرسِل';
  static const String tripartitePickDestHint = 'اختر الطرف المُستلِم';
  static const String tripartiteAffectedLabel = 'حسابك الوسيط';
  static const String tripartitePickAffectedHint = 'اختر حسابك (مثل النقدية)';
  static const String tripartiteCreatedSuccess = 'تم حفظ التحويل الثلاثي بنجاح';
  static const String tripartiteDraftSaved = 'تم حفظ مسودة التحويل بنجاح';
  static const String tripartiteNewTitle = 'تحويل جديد';
  static const String tripartiteSelectAccountHint = 'اختر الحساب';
  static const String tripartiteContingentHint =
      'هذا السند معلّق حتى يتم تأكيد سند القبض المقابل.';
  static const String tripartiteReleasedInfo =
      'تم تحرير سند الصرف — يمكنك الآن مشاركته وتوقيعه.';
  static const String tripartiteBridgeTooltip = 'تحويل وسيط';
  static const String tripartiteFlowTitle = 'مسار التحويل';
  static const String tripartiteFlowSource = 'المصدر';
  static const String tripartiteFlowMediator = 'الوسيط (أنت)';
  static const String tripartiteFlowDestination = 'الوجهة';
  static const String tripartiteReceiptLeg = 'سند القبض';
  static const String tripartitePaymentLeg = 'سند الصرف';
  static const String tripartiteGroupLabel = 'مجموعة التحويل';

  static const String clearingAccountName = 'مقاصة الحوالات';
  static const String tripartiteNoClearingAccount = 'لا يوجد حساب مقاصة حوالات';
  static const String tripartiteSelectAccounts = 'الرجاء اختيار الحسابات';

  // ── Statement of Account Chat (كشف الحساب) ─────────────────────────────
  static const String statementChatTitle = 'كشف الحساب';
  static const String statementChatSearchHint =
      'بحث بالبيان أو الرقم أو المبلغ…';
  static const String statementChatEmpty = 'لا توجد سندات بين الطرفين بعد.';
  static const String statementChatEmptyFiltered =
      'لا سندات مطابقة للتصفية الحالية.';
  static const String statementFilterTitle = 'تصفية كشف الحساب';
  static const String statementFilterStatusSection = 'حالة الموافقة (اللون)';
  static const String statementStatusConfirmed = 'مؤكد (أخضر)';
  static const String statementStatusReceipt = 'سند قبض (أزرق)';
  static const String statementStatusPending = 'بانتظار الموافقة (برتقالي)';
  static const String statementStatusRejected = 'مرفوض (أحمر)';
  static const String statementUnifiedTitle = 'سجل السندات (موحد)';
  static const String statementUnreadMessages = 'رسائل جديدة غير مقروءة';
  static const String statementMediatorPrefix = 'حوالة عبر الوسيط: ';
  static const String statementFeePrefix = 'الرسوم: ';
  static const String statementDateThisMonth = 'هذا الشهر';
  static const String statementDateLastQuarter = 'الربع السابق';
  static const String statementDateThisYear = 'هذه السنة';
  static const String statementIncludePreviousBalance =
      'تضمين رصيد ما قبل الفترة';
  static const String statementIncludePreviousBalanceHint =
      'يعرض الرصيد الافتتاحي المحسوب من جميع السندات قبل تاريخ البداية.';
  static const String statementBroughtForward = 'رصيد مرحّل';
  static const String statementFinalBalance = 'الرصيد النهائي';
  static const String statementBalanceForYou = 'لصالحك';
  static const String statementBalanceAgainstYou = 'مدين (عليك)';
  static const String statementBalanceSettled = 'مسوّى';
  static const String statementRunningBalance = 'الرصيد';
  static const String statementVoucherCount = 'سند';
  static const String statementViewModeMy = 'حسبتي';
  static const String statementViewModeOther = 'حسبة الطرف الآخر';
  static const String statementChatWithdraw = 'سحب';

  static const String settingsGroupProfile = 'بيانات الحساب والهوية';
  static const String settingsGroupBackup = 'النسخ الاحتياطي والأرشفة';
  static const String settingsGroupTemplates = 'إعداد القوالب (PDF والرسائل)';
  static const String settingsGroupCurrency = 'العملات والتحويل';
  static const String settingsGroupSecurity = 'القفل والحماية';
  static const String settingsGroupSupport = 'الدعم، السياسات والأسئلة الشائعة';

  static const String settingsPrivacyPolicy = 'سياسة الخصوصية';
  static const String settingsTermsOfUse = 'شروط الاستخدام';
  static const String settingsFaqs = 'الأسئلة الشائعة (FAQ)';
  static const String settingsContactSupport = 'التواصل مع الدعم الفني';
  static const String settingsReportIssue = 'الإبلاغ عن مشكلة أو اقتراح';
  static const String settingsVersionInfo = 'معلومات الإصدار';
  static const String settingsGroupNotifications = 'تفضيلات الإشعارات';

  // ── Profile Management ──────────────────────────────────────────────────
  static const String profileDetailsSection = 'بيانات الحساب والنشاط';
  static const String profileNameLabel = 'الاسم الكامل';
  static const String profilePhoneLabel = 'رقم الهاتف';
  static const String profileWhatsAppLabel = 'رقم الواتساب';
  static const String profileEmailLabel = 'البريد الإلكتروني';
  static const String profileUpdateAction = 'حفظ التعديلات';
  static const String profileUpdateSuccess =
      'تم تحديث بيانات ملفك الشخصي بنجاح.';
  static const String profileImageUpload = 'تغيير الصورة';
  static const String profileLogoUpload = 'تغيير الشعار';

  // ── Notification Settings ──────────────────────────────────────────────
  static const String notifPeerActivityTitle = 'أنشطة الطرف الآخر';
  static const String notifPeerActivityDesc =
      'استلام إشعارات السندات، الحوالات، وطلبات الحوالة القادمة من الآخرين.';
  static const String notifSelfActivityTitle = 'أنشطتي العملياتية';
  static const String notifSelfActivityDesc =
      'إظهار إشعارات وتنبيهات صوتية للعمليات التي أقوم بها بنفسي.';
  static const String notifSoundEnabled = 'تفعيل أصوات التنبيه';
  static const String notifVibrationEnabled = 'تفعيل الاهتزاز';
  static const String notifDirectCategories = 'الفئات المباشرة';
  static const String notifMediaAlerts = 'التنبيهات والوسائط';
  static const String notifSoundDesc = 'تشغيل نغمة عند وصول إشعار جديد.';
  static const String notifVibrationDesc =
      'اهتزاز الهاتف عند وصول إشعارات هامة.';

  // ── Notification Channels ──────────────────────────────────────────────
  static const String channelImportantTitle = 'إشعارات قيد الهامة';
  static const String channelImportantDesc =
      'تنبيهات الحوالات والسندات المباشرة';
  static const String channelImportantSummary = 'تنبيه مالي';
  static const String channelDefaultTitle = 'إشعارات قيد العامة';
  static const String channelDefaultDesc =
      'تحديثات النظام والمزامنة في الخلفية';

  // ── Notification Permission ────────────────────────────────────────────
  static const String notifPermissionDeniedTitle = 'الإشعارات معطّلة';
  static const String notifPermissionDeniedBody =
      'لقد رفضت إذن الإشعارات سابقاً. لتفعيلها، يجب منح الإذن يدوياً من إعدادات النظام.';
  static const String notifPermissionOpenSettings = 'فتح إعدادات التطبيق';
  static const String notifPermissionGranted = 'الإشعارات مفعّلة';
  static const String notifPermissionGrantedBody =
      'تم تفعيل الإشعارات بنجاح. يمكنك الآن التحكم في نوع الإشعارات أدناه.';

  // ── Sync Event Notifications ───────────────────────────────────────────
  static const String syncClaimTitle = 'طلب جديد';
  static const String syncClaimBody = 'تم استلام طلب سند جديد من شريكك.';
  static const String syncAcceptanceTitle = 'تم الاعتماد';
  static const String syncAcceptanceBody = 'تم قبول السند الخاص بك ومزامنته.';
  static String syncAcceptanceInboxBody(String shortId) =>
      'تم اعتماد سند الصرف الخاص بك (#$shortId).';

  // ── Threaded Financial Interactions ──────────────────────────────────────
  static const String voucherWithdrawAction = 'سحب السند';
  static const String voucherWithdrawConfirmTitle = 'تأكيد سحب السند';
  static const String voucherWithdrawConfirmBody =
      'سيتم سحب هذا السند نهائياً. لن يظهر عند الطرف المقابل ولا يمكن التراجع.';
  static const String voucherWithdrawnSuccess = 'تم سحب السند بنجاح.';
  static const String voucherReversalIndicator = '↩ مرتجع';
  static const String voucherSettlementIndicator = '✓ تسوية';
  static const String voucherCreateReversal = 'إنشاء مرتجع';
  static const String voucherCreateSettlement = 'تسوية';
  static const String voucherRejectionReasonLabel = 'سبب الرفض';
  static const String voucherOriginLabel = 'السند الأصلي';
  static const String voucherReciprocalMatchTitle = 'تطابق مكتشف';
  static const String voucherReciprocalMatchBody =
      'تم اكتشاف سند مطابق. هل تريد دمجهما في معاملة واحدة مؤكدة؟';
  static const String voucherMergeAction = 'دمج';
  static const String p2pScanTitle = 'مزامنة شخصية (P2P)';
  static const String p2pScanSubtitle =
      'امسح رمز الطرف الآخر للمزامنة المباشرة';
  static const String p2pSyncSuccess = 'تمت المزامنة المباشرة بنجاح.';
  static const String p2pSyncFailed = 'فشلت المزامنة المباشرة.';

  // ── Cost and Profit Centers ──────────────────────────────────────────────
  static const String costCentersTitle = 'مراكز التكلفة والربح';
  static const String addCostCenterFab = 'مركز جديد';
  static const String newCostCenterTitle = 'مركز تكلفة/ربح جديد';
  static const String searchCostCentersHint = 'بحث باسم المركز…';
  static const String costCentersEmpty =
      'لا توجد مراكز تكلفة بعد. أضف مركزاً جديداً.';
  static const String costCentersEmptyFiltered =
      'لا نتائج مطابقة للبحث أو التصفية.';

  static const String costCenterTypeCostGroup = 'مراكز التكلفة';
  static const String costCenterTypeProfitGroup = 'مراكز الربح';
  static const String showSuspendedLabel = 'عرض الموقوف';
  static const String allLabel = 'الكل';
  static const String errorTitle = 'خطأ';
  static const String costCenterDetailTitle = 'تفاصيل المركز';
  static const String costCenterNameLabel = 'اسم المركز';
  static const String costCenterDescriptionLabel = 'الوصف (اختياري)';
  static const String costCenterBudgetLabel = 'الميزانية (اختياري — ريال)';
  static const String costCenterTypeLabel = 'نوع المركز';
  static const String costCenterTypeCost = 'مركز تكلفة';
  static const String costCenterTypeProfit = 'مركز ربح';
  static const String costCenterCreatedSuccess = 'تم إنشاء المركز بنجاح.';
  static const String costCenterSuspendAction = 'إيقاف المركز';
  static const String costCenterActivateAction = 'تفعيل المركز';
  static const String costCenterSuspendedBadge = 'موقوف';
  static const String costCenterBudgetPrefix = 'الميزانية:';
  static const String costCenterViewVouchers = 'عرض السندات والنشاط';
  static const String costCenterVoucherCountLabel = 'عدد السندات';
  static const String costCenterTotalLabel = 'إجمالي مؤكد';
  static const String costCenterOpenLedger = 'عرض سجل السندات كمحادثة';
  static const String costCenterLedgerTitle = 'سجل السندات';
  static const String costCenterLedgerSubtitle =
      'يعرض جميع سندات القبض والصرف المرتبطة بهذا المركز في واجهة محادثة.';
  // Create page
  static const String costCenterTypeSelectorLabel = 'نوع المركز';
  static const String costCenterDimensionSelectorLabel =
      'الأبعاد الحياتية المرتبطة';
  static const String costCenterNameHint = 'اسم المركز *';
  static const String costCenterNameValidator = 'يرجى إدخال الاسم.';
  static const String costCenterDescHint = 'الوصف (اختياري)';
  static const String costCenterBudgetHint = 'الميزانية (اختياري — ريال)';
  static const String costCenterBudgetNoneHint = '0 = بلا حد';
  static const String costCenterSaveAction = 'إنشاء المركز';
  static const String costCenterCreatedSnackbar =
      'تم إنشاء مركز التكلفة بنجاح.';
  // Detail page actions
  static const String costCenterSuspendConfirmTitle = 'تأكيد الإيقاف';
  static const String costCenterActivateConfirmTitle = 'تأكيد التفعيل';
  static const String costCenterEditAction = 'تعديل المركز';
  static const String costCenterDeleteAction = 'حذف المركز';
  static const String costCenterSuspendSnackbar = 'تم إيقاف عمل مركز التكلفة.';
  static const String costCenterActivateSnackbar =
      'تم إعادة تفعيل مركز التكلفة.';
  // Categories
  static const String dimCategorySpatial = 'بُعد مكاني';
  static const String dimCategoryIndividual = 'بُعد الأفراد';
  static const String dimCategoryProject = 'بُعد المشاريع';

  // ── Cost Center Dashboard (Redesign) ─────────────────────────────────────
  static const String costCenterKpiSection = 'مؤشرات الأداء';
  static const String costCenterActivitySection = 'النشاط الأخير';
  static const String costCenterTrendSection = 'الاتجاه الشهري (6 أشهر)';
  static const String costCenterDimensionBreakdownTitle = 'توزيع الأبعاد';
  static const String costCenterBudgetGaugeTitle = 'استخدام الميزانية';
  static const String costCenterAvgVoucherSize = 'متوسط السند';
  static const String costCenterCurrentMonthLabel = 'هذا الشهر';
  static const String costCenterGrowthLabel = 'النمو';
  static const String costCenterAllDimensionsFilter = 'الكل';
  static const String costCenterViewMoreVouchers = 'عرض السجل كاملاً';
  static const String costCenterQuickPayAction = 'سند صرف';
  static const String costCenterQuickReceiveAction = 'سند قبض';
  static const String costCenterNoRecentVouchers = 'لا توجد معاملات حديثة.';
  static const String costCenterNoBudget = 'بلا حد';
  static const String costCenterOverBudgetWarning = 'تجاوز الميزانية!';
  static const String costCenterActiveBadge = 'نشط';
  static const String costCenterNoTrendData =
      'لا توجد حركة مالية مؤكدة خلال الفترة.';
  static const String costCenterNoDimensionData =
      'لا توجد سندات مصنفة بالأبعاد.';

  // ── Navigation ──────────────────────────────────────────────────────────
  static const String navCostCentersTab = 'المراكز';

  // ── Enhanced Voucher Detail Page ────────────────────────────────────────
  static const String voucherPreviewCardTitle = 'معاينة السند';
  static const String createdAtLabel = 'تاريخ الإنشاء';
  static const String voucherConfirmedAtLabel = 'تاريخ التأكيد';
  static const String voucherSettledAtLabel = 'تاريخ التسوية';
  static const String voucherAttachmentsSection = 'المرفقات';
  static String voucherAttachmentCountLabel(int count) => '$count مرفق';
  static const String voucherAttachmentSizeLabel = 'الحجم';
  static const String voucherCollateralSection = 'رهن / ضمان';
  static const String voucherCollateralValueLabel = 'قيمة الرهن';
  static const String voucherCollateralExpiryLabel = 'تاريخ الاستحقاق';
  static const String voucherCollateralStatusLabel = 'حالة الرهن';
  static const String voucherCollateralSettlementsTitle = 'تسويات الرهن';
  static String voucherCollateralSettlementLink(int index) =>
      'سند تسوية #$index';
  static const String voucherCostCentersSection = 'مراكز التكلفة / الربح';
  static const String voucherCostCenterTypeCost = 'تكلفة';
  static const String voucherCostCenterTypeProfit = 'ربح';
  static const String voucherOriginDocumentButton = 'عرض السند الأصلي';
  static const String voucherSignatureStatusLabel = 'حالة التوقيعات';
  static const String voucherSenderLabel = 'المرسل';
  static const String voucherReceiverLabel = 'المستلم';

  // ── Accruals (Financial Obligations) ────────────────────────────────────
  static const String accrualCreateTitle = 'إضافة التزام مالي';
  static const String accrualNameLabel = 'مسمى الالتزام';
  static const String accrualNameHint = 'مثلاً: إيجار الشقة، اشتراك إنترنت';
  static const String accrualNameRequired = 'يرجى إدخال مسمى الالتزام.';
  static const String accrualAmountLabel = 'المبلغ التقديري';
  static const String accrualAmountInvalid =
      'يرجى إدخال مبلغ صالح أكبر من صفر.';
  static const String accrualFrequencyLabel = 'تكرار الالتزام';
  static const String accrualNextDueDateLabel = 'تاريخ الاستحقاق القادم';
  static const String accrualSourceAccountLabel = 'حساب الدفع';
  static const String accrualSourceAccountHint = 'اختر حساب الدفع (كاش، بنك…)';
  static const String accrualDestAccountLabel = 'حساب الاستحقاق';
  static const String accrualDestAccountHint = 'اختر حساب المصروف (سكن، غذاء…)';
  static const String accrualDestAccountRequired =
      'يرجى اختيار الحساب المستهدف.';
  static const String accrualCategoryLabel = 'البعد الحياتي المرتبط';
  static const String accrualDescriptionLabel = 'ملاحظات (اختياري)';
  static const String accrualSaveAction = 'حفظ الالتزام';
  static const String accrualSavedSuccess = 'تم حفظ الالتزام بنجاح.';

  // Accrual list page
  static const String accrualListTitle = 'الالتزامات والاستحقاقات';
  static const String accrualAddFab = 'التزام جديد';
  static const String accrualMonthlySummaryLabel =
      'إجمالي الالتزامات الشهرية المقدرة';
  static const String accrualActiveLabel = 'نشط';
  static const String accrualDueSoonLabel = 'مستحق قريباً';
  static const String accrualEmptyState = 'لا توجد التزامات مجدولة بعد.';
  static const String accrualProcessConfirmTitle = 'تأكيد تنفيذ الالتزام';
  static String accrualProcessConfirmBody(double amount, String currency) =>
      'هل تود تسجيل مبلغ $amount $currency كعملية دفع حقيقية؟';
  static const String accrualProcessConfirmAction = 'نعم، تم الدفع';
  static const String accrualProcessedSuccess =
      'تم تنفيذ الاستحقاق وتسجيل العملية بنجاح.';
  static const String accrualNextDuePrefix = 'الاستحقاق القادم';
  static const String accrualPayTooltip = 'تسجيل عملية دفع';

  // ── Income Streams Module ───────────────────────────────────────────────

  // Page titles & tabs
  static const String incomeStreamsTitle = 'تدفقات الدخل والمصروفات';
  static const String incomeStreamsTabIncome = 'مصادر الدخل';
  static const String incomeStreamsTabPossessions = 'الممتلكات';
  static const String incomeStreamsTabExpenses = 'المصروفات';
  static const String incomeStreamsAddSource = 'إضافة مصدر';
  static const String incomeStreamsAddExpense = 'إضافة تصنيف';

  // Empty states
  static const String incomeStreamsEmpty =
      'لا توجد مصادر دخل مسجلة حالياً.\nأضف أصلاً استثمارياً أو مهنة لتبدأ.';
  static const String possessionsEmpty = 'لا توجد ممتلكات شخصية مسجلة حالياً.';
  static const String expenseCategoriesEmpty =
      'لا توجد تصنيفات مصروفات حالياً.';

  // Source type selection sheet
  static const String incomeSourceTypeSheetTitle = 'ما نوع الإضافة؟';
  static const String incomeSourceTypeSheetSubtitle =
      'اختر نوع مصدر الدخل أو الممتلك الذي تودّ تسجيله';

  static const String incomeSourceInvestmentAsset = 'أصل استثماري';
  static const String incomeSourceInvestmentAssetDesc =
      'عقارات، أسهم، مشاريع — كل ما يدرّ دخلاً دورياً';
  static const String incomeSourceProfession = 'مهنة / عمل حر';
  static const String incomeSourceProfessionDesc =
      'وظيفة، حرفة، استشارة — مصدر دخل من العمل الشخصي';
  static const String incomeSourceOther = 'مصدر دخل آخر';
  static const String incomeSourceOtherDesc =
      'إيجار، منحة، دخل جانبي — أي مصدر دخل غير مصنف';
  static const String incomeSourcePossession = 'ممتلك شخصي';
  static const String incomeSourcePossessionDesc =
      'سيارة، أثاث، إلكترونيات — أصول مستهلَكة لا تدر دخلاً';

  // Profession creation wizard
  static const String professionWizardTitle = 'تسجيل مهنة / عمل حر';
  static const String professionWizardDesc =
      'سجّل مهنتك كمصدر دخل مستقل يتم تتبع إيراداته تلقائياً';
  static const String professionAccountNameLabel = 'اسم الحساب';
  static const String professionAccountNameHint =
      'مثال: إيرادات التطوير، استشارات هندسية...';
  static const String professionNameLabel = 'اسم المهنة';
  static const String professionNameHint =
      'مثال: تطوير تطبيقات، تصميم جرافيك، محاسبة...';
  static const String professionLicenseLabel = 'رقم الترخيص / السجل (اختياري)';
  static const String professionLicenseHint = 'رقم السجل التجاري أو الترخيص';
  static const String professionHourlyRateLabel = 'معدل الساعة (اختياري)';
  static const String professionStartDateLabel = 'تاريخ بدء المهنة';
  static const String professionStartDateHint = 'اختر تاريخ البدء (اختياري)';
  static const String professionNotesLabel = 'ملاحظات مرجعية (اختياري)';
  static const String professionNotesHint = 'تفاصيل إضافية عن المهنة...';
  static const String professionSubmitButton = 'تأكيد وتسجيل المهنة';
  static const String professionSubmitNote =
      'سيتم إنشاء حساب إيرادي مرتبط بهذه المهنة لتتبع الدخل تلقائياً.';

  // Income stream card KPIs
  static const String incomeStreamTotalYield = 'إجمالي العائد';
  static const String incomeStreamTotalEarned = 'إجمالي المكتسب';
  static const String incomeStreamCurrentValue = 'القيمة الحالية';
  static const String incomeStreamBalance = 'الرصيد';
  static const String incomeStreamAcquisitionValue = 'قيمة الاقتناء';
  static const String incomeStreamProfessionField = 'المجال';
  static const String incomeStreamExpenseCategory = 'تصنيف إنفاق';

  // ── Database Recovery / Key Mismatch ─────────────────────────────────────
  static const String dbKeyMismatchTitle = 'تعذّر فتح قاعدة البيانات';
  static const String dbKeyMismatchBody =
      'يوجد ملف قاعدة بيانات مشفّرة على هذا الجهاز، لكن مفتاح التشفير الحالي لا يتطابق.\n\n'
      'قد يحدث هذا عند تسجيل الدخول بحساب مختلف عن الحساب الذي أنشأ القاعدة الأصلية.\n\n'
      'يُرجى إدخال المفتاح الأساسي (عبارة الـ 24 كلمة) لفتح القاعدة، أو البدء من جديد.';
  static const String dbKeyMismatchRetryFailed =
      'المفتاح المُدخل غير صحيح أو لا يتطابق مع القاعدة الموجودة. حاول مرة أخرى بعبارة مختلفة.';
  static const String dbEnterPrimaryKeyAction = 'إدخال المفتاح الأساسي';
  static const String dbMnemonicHint =
      'أدخل عبارة الاسترداد المكونة من 24 كلمة…';
  static const String dbUnlockAction = 'فتح القاعدة';
  static const String dbRetryAction = 'إعادة المحاولة';
  static const String dbStartFreshAction =
      'البدء من جديد (حذف القاعدة الحالية)';
  static const String dbStartFreshConfirmTitle = 'تأكيد الحذف والبدء من جديد';
  static const String dbStartFreshConfirmBody =
      'سيتم حذف جميع البيانات المالية المخزنة على هذا الجهاز نهائياً.\n\n'
      'لا يمكن التراجع عن هذا الإجراء. هل أنت متأكد؟';
  static const String dbStartFreshConfirmAction = 'حذف والبدء من جديد';
  static const String dbOpenErrorTitle = 'خطأ في فتح قاعدة البيانات';
  static const String dbOpenErrorBody =
      'تعذّر فتح قاعدة البيانات بسبب خطأ غير متوقع. يُرجى إعادة المحاولة أو التواصل مع الدعم الفني.';
  static const String dbOpeningProgress = 'جاري فتح قاعدة البيانات المشفّرة…';

  // ── Post-Auth Gate / Onboarding Flow ──────────────────────────────────
  static const String gateCheckingStatus = 'جاري التحقق من حالة حسابك…';
  static const String gateCheckingBackups = 'جاري البحث عن نسخ احتياطية…';

  // Backup restore options for returning accounts
  static const String gateRestoreTitle = 'استعادة بياناتك';
  static const String gateRestoreSubtitle =
      'وجدنا نسخاً احتياطية مرتبطة بحسابك. اختر طريقة الاستعادة.';
  static const String gateRestoreLocalOption = 'استعادة النسخة المحلية';
  static const String gateRestoreDriveOption = 'استعادة من Google Drive';
  static const String gateRestoreAndKeepIdentity =
      'استعادة مع الاحتفاظ بالهوية الرقمية السابقة';
  static const String gateRestoreNewIdentity =
      'استعادة البيانات فقط (هوية رقمية جديدة)';
  static const String gateSkipRestore = 'تخطي والبدء بحساب جديد تماماً';

  // No backups found — identity recovery
  static const String gateNoBackupTitle = 'لا توجد نسخة احتياطية';
  static const String gateNoBackupSubtitle =
      'لم نعثر على نسخ احتياطية. إذا كنت تمتلك المفتاح الأساسي (24 كلمة)، يمكنك استعادة هويتك الرقمية.';
  static const String gateEnterPrimaryKey = 'إدخال المفتاح الأساسي';
  static const String gateBypassIdentity =
      'متابعة بهوية رقمية جديدة (غير مستحسن)';

  // Identity setup prompt
  static const String gateIdentitySetupTitle = 'إعداد الهوية الرقمية';
  static const String gateIdentitySetupSubtitle =
      'لإتمام حماية حسابك، سيتم إنشاء مفتاح التشفير الخاص بك.';

  // Device lock setup prompt
  static const String gateDeviceLockTitle = 'حماية التطبيق';
  static const String gateDeviceLockSubtitle =
      'حماية التطبيق عند ترك الجهاز بدون مراقبة.';
  static const String gateSetupBiometric = 'تفعيل البصمة أو الوجه';
  static const String gateSetupPin = 'تعيين رمز قفل رقمي';
  static const String gateSkipDeviceLock = 'المتابعة بدون قفل (غير مستحسن)';
  static const String gateSetupComplete = 'اكتمل الإعداد';
  static const String gateSetupCompleteBody =
      'تم تأمين حسابك بنجاح. يمكنك الآن استخدام التطبيق.';
  static const String gateContinueToApp = 'الدخول إلى التطبيق';

  // Network error during server identity check
  static const String gateNetworkErrorTitle = 'تعذّر التحقق من السيرفر';
  static const String gateNetworkErrorSubtitle =
      'لم نتمكن من التحقق مما إذا كانت لديك هوية رقمية مسجلة مسبقاً. '
      'قد يكون السبب ضعف الاتصال بالإنترنت.';
  static const String gateNetworkRetry = 'إعادة المحاولة';
  static const String gateNetworkRetryHint =
      'تحقق من الاتصال بالإنترنت ثم أعد المحاولة.';
  static const String gateNetworkCreateNew =
      'إنشاء هوية جديدة (حساب جديد تماماً)';
  static const String gateNetworkCreateNewWarning =
      'تحذير: إذا كنت تمتلك هوية سابقة، فستفقد القدرة على التعامل مع السندات الموقعة بها.';
}
