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
      case StringKeys.shareAsWhatsappTooltip:
        return shareAsWhatsappTooltip;
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
  static const String filterNatureDebit = 'مدين (لك)';
  static const String filterNatureCredit = ' دائن (عليك)';
  static const String natureDebitShort = 'مدين (لك)';
  static const String natureCreditShort = ' دائن (عليك)';
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

  // Accounts — edit
  static const String editAccountTitle = 'تعديل الحساب';
  static const String editAccountTooltip = 'تعديل بيانات الحساب';
  static const String saveAccountChanges = 'حفظ التعديلات';
  static const String accountUpdatedSuccess = 'تم تحديث بيانات الحساب بنجاح.';
  static const String editAccountClassificationLocked =
      'لا يمكن تغيير التصنيف بعد إنشاء الحساب.';
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
  static const String trialBalanceColDebit = 'إجمالي الدائن (عليك)';
  static const String trialBalanceColCredit = 'إجمالي المدين (لك)';
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
  static const String balancedLabel = 'متوازن ';
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
  static const String settingsSystemTitle = 'إعدادات النظام';
  static const String settingsSectionDataSync = 'البيانات والمزامنة';
  static const String settingsSyncPrivacyTitle = 'خصوصية المزامنة';
  static const String settingsBackupSubtitle = 'إدارة النسخ الاحتياطي واستعادة البيانات';
  static const String settingsSyncPrivacySubtitle = 'تشفير وحماية البيانات المتزامنة';
  static const String settingsSectionCustomization = 'التخصيص';
  static const String settingsGroupAppearance = 'تخصيص المظهر';
  static const String settingsAppearanceSubtitle = 'تخصيص الثيم واللغة';
  static const String appearanceThemeMode = 'وضع المظهر';
  static const String appearanceLanguage = 'لغة التطبيق';
  static const String themeSystem = 'تلقائي حسب النظام';
  static const String themeLight = 'الوضع الفاتح';
  static const String themeDark = 'الوضع الداكن';
  static const String langArabic = 'العربية';
  static const String langEnglish = 'English (قريباً)';
  static const String settingsTemplatesSubtitle = 'تخصيص قوالب الطباعة والفواتير';
  static const String settingsSectionSecurityNotifications = 'الأمان والإشعارات';
  static const String settingsSecuritySubtitle = 'الرمز السري والمصادقة البيومترية';
  static const String settingsNotificationsSubtitle = 'تفضيلات التنبيهات والأصوات';
  static const String settingsSectionSupport = 'الدعم الفني';
  static const String settingsSupportSubtitle = 'التواصل مع خدمة العملاء والمساعدة';
  static const String accrualsAndLiabilitiesTitle = 'الاستحقاقات والالتزامات';
  static const String auditLogTitle = 'سجل التدقيق';
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
  static const String tripartiteDisabledDialogTitle =
      'خيار التحويل الوسيط غير مفعل';
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
  static const String shareAsWhatsappTooltip = 'مشاركة كشف الحساب';
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
  static const String statementBalanceAgainstYou = 'دائن (عليك)';
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
  static const String voucherSettlementIndicator = ' تسوية';
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

  static const String costCenterTypeCostGroup = 'مراكز التكلفة';
  static const String costCenterTypeProfitGroup = 'مراكز الربح';
  static const String showSuspendedLabel = 'عرض الموقوف';
  static const String allLabel = 'الكل';
  static const String errorTitle = 'خطأ';
  static const String costCenterDetailTitle = 'تفاصيل المركز';
  static const String costCenterNameLabel = 'اسم المركز';
  static const String costCenterDescriptionLabel = 'الوصف (اختياري)';
  static const String costCenterBudgetLabel = 'الميزانية (اختياري — ﷼)';
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
  static const String costCenterBudgetHint = 'الميزانية (اختياري — ﷼)';
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

  // Logout
  static const String logoutAction = 'تسجيل الخروج';
  static const String logoutConfirmTitle = 'تأكيد تسجيل الخروج';
  static const String logoutConfirmBody =
      'هل أنت متأكد من رغبتك في تسجيل الخروج؟';

  // ── Account Deletion ──────────────────────────────────────────────────
  static const String profileDeleteAccountAction = 'حذف الحساب نهائياً';
  static const String profileDeleteAccountWarningTitle =
      'تحذير: حذف الحساب والبيانات';
  static const String profileDeleteAccountWarningBody =
      'هذا الإجراء سيقوم بما يلي:\n'
      '• حذف جميع بياناتك المالية من هذا الجهاز.\n'
      '• حذف جميع النسخ الاحتياطية المحلية وعلى Google Drive.\n'
      '• تعطيل حسابك على السيرفر (Soft delete).\n\n'
      'تحذير: لا يمكن التراجع عن هذا الإجراء أبداً.';
  static const String profileDeleteAccountConfirmLabel =
      'أوافق على محو جميع بياناتي نهائياً';
  static const String profileDeleteAccountExecute = 'محو بيانات الحساب';
  static const String profileDeleteAccountSuccess =
      'تم محو الحساب وجميع البيانات بنجاح.';

  // --- Auto-generated extracted strings ---
  static const String curacao = 'كوراساو';
  static const String burkinaFaso = 'بوركينا فاسو';
  static const String anUnexpectedErrorOccurred = 'حدث خطأ غير متوقع أثناء معالجة التوقيع.';
  static const String theSystemWillAutomatically = 'سيقوم النظام بتتبع الأرباح الموزعة من هذا الأصل تلقائياً';
  static const String usersBlockedFromSyncing = 'المستخدمون المحظورون من المزامنة معك.';
  static const String theSyncTagCould = 'تعذر قراءة علامة المزامنة.';
  static const String forEachAccountMerge = 'لكل حساب: دمج مع موجود، أو إنشاء جديد، أو تخطي';
  static const String selectTheCountry = 'تحديد الدولة';
  static const String unableToSearchBy = 'تعذر البحث برقم الهاتف.';
  static const String cameroon = 'الكاميرون';
  static const String callNow = 'دعوة الآن';
  static const String dangerZone = 'منطقة الخطر';
  static const String housingAndLiving = 'السكن والمعيشة';
  static const String importAccountsAndFinancial = 'استيراد الحسابات والحركات المالية من حزمة JSON';
  static const String theBondEntriesCould = 'تعذر قراءة قيود السند.';
  static const String importData = 'استيراد بيانات';
  static const String signatureStatus = 'حالة التوقيع';
  static const String unableToReadDimensions = 'تعذر قراءة الأبعاد.';
  static const String s1 = '١';
  static const String finland = 'فنلندا';
  static const String frenchPolynesia = 'بولينيزيا الفرنسية';
  static const String writeMessageDetailsHere = 'اكتب تفاصيل الرسالة هنا...';
  static const String creditor = 'دائن';
  static const String madagascar = 'مدغشقر';
  static const String offerForSale = 'عرض للبيع';
  static const String pleaseEnterADimension = 'يرجى إدخال اسم البُعد.';
  static const String registrationDataCreditTo = 'بيانات القيد (الدائن) - إلى حساب العميل المستلم:';
  static const String privacyProtected = 'محمي بالخصوصية';
  static const String pleaseSelectTheSource = 'يرجى تحديد حساب المصدر (الصندوق/البنك).';
  static const String dearue000 = 'عزيزي \\uE000';
  static const String accountName = 'اسم الحساب';
  static const String unableToReadDimension = 'تعذر قراءة توزيع الأبعاد.';
  static const String image = 'صورة';
  static const String puertoRico = 'بورتوريكو';
  static const String thereIsAlreadyAn = 'يوجد حساب مسجل مسبقاً برقم الهاتف هذا.';
  static const String openingBalance = 'الرصيد الافتتاحي:';
  static const String qayd = 'قيد / Qayd';
  static const String accountsCouldNotBe = 'تعذر إنشاء الحسابات دفعة واحدة.';
  static const String cookIslands = 'جزر كوك';
  static const String tryChangingTheFilters = 'جرب تغيير عوامل التصفية';
  static const String chooseTheConversionType = 'اختر نوع التحويل';
  static const String niger = 'النيجر';
  static const String reviewAndEditThe = 'مراجعة وتعديل نص المشاركة';
  static const String typeDebitcredit = 'النوع (مدين/دائن)';
  static const String theDatabaseDoesNot = 'قاعدة البيانات غير موجودة.';
  static const String gambia = 'غامبيا';
  static const String determineWhoCanSync = 'حدد من يمكنه مزامنة السندات معك واكتشاف مفتاحك العام.';
  static const String chooseAccount = 'اختر الحساب';
  static const String theLastOpenDocument = 'تعذر تحديث آخر سند مفتوح.';
  static const String invalidData = 'بيانات غير صالحة.';
  static const String theListHasBeen = 'تم تحديث القائمة بنجاح.';
  static const String somalia = 'الصومال';
  static const String s0123456789 = '٠١٢٣٤٥٦٧٨٩';
  static const String noDraftReceiptMatching = 'لم يتم العثور على مسودة إيصال مطابقة لهذا الإجمالي والتاريخ.';
  static const String signatureOfTheSending = 'توقيع الطرف المرسل';
  static const String fixedAssetsDepreciated = 'أصول ثابتة (مهلكة)';
  static const String createNew = 'إنشاء جديد';
  static const String theFileDoesNot = 'الملف لا يحتوي على قاعدة بيانات.';
  static const String euro = 'يورو';
  static const String customTaxonomyNameIs = 'اسم التصنيف المخصص مطلوب.';
  static const String portugal = 'البرتغال';
  static const String restoreTheSelectedVersion = 'استعادة النسخة المحددة';
  static const String registrationDataToThe = 'بيانات القيد - إلى حساب العميل:';
  static const String svalbardAndJanMayen = 'سفالبارد وجان مايان';
  static const String accountStatement = 'كشف الحساب';
  static const String iran = 'إيران';
  static const String billOfExchange = 'سند صرف';
  static const String botswana = 'بوتسوانا';
  static const String startImport = 'بدء الاستيراد';
  static const String syncPrivacy = 'خصوصية المزامنة';
  static const String oppositeParty = 'الطرف المقابل';
  static const String unableToReadThe = 'تعذر قراءة قائمة الحسابات.';
  static const String toBeSure = 'تأكيد';
  static const String theSenderAndRecipient = 'لا يمكن أن يكون المرسل والمستلم نفس الطرف.';
  static const String togo = 'توغو';
  static const String selectCostCenter = 'اختر مركز التكلفة';
  static const String importBonds = 'استيراد السندات';
  static const String cashAndLiquidity = 'نقدية وسيولة';
  static const String bondsCouldNotBe = 'تعذر عد السندات.';
  static const String accountStatement1 = 'كشف حساب';
  static const String settled = 'تمت التسوية';
  static const String drawn = 'مسحوب';
  static const String invalidDateRange = 'نطاق التواريخ غير صالح.';
  static const String accessToContacts = 'الوصول لجهات الاتصال';
  static const String pitcairnIsland = 'جزيرة بيتكيرن';
  static const String americanSamoa = 'ساموا الأمريكية';
  static const String theApplicationIsIn = 'التطبيق في وضع التعليق: لا يمكن حفظ التعديلات حتى يتم استئناف الخدمة.';
  static const String trySearchingWithOther = 'جرب البحث بكلمات أخرى أو تغيير عوامل التصفية';
  static const String theFileCouldNot = 'تعذر فتح الملف كقاعدة بيانات مشفّرة. تأكد أنه نسخة احتياطية من قيد وأن المفتاح لم يتغيّر.';
  static const String newStatus = 'الحالة الجديدة';
  static const String iReceived = 'استلمت';
  static const String bahrain = 'البحرين';
  static const String pleaseEnterTheSale = 'يرجى إدخال قيمة البيع';
  static const String allowsEveryoneExceptUsers = 'يسمح للجميع ما عدا المستخدمين في قائمة الحظر.';
  static const String deposit = 'إيداع';
  static const String doubleConversionWithBox = 'تحويل مزدوج مع الصندوق';
  static const String theCodeDoesNot = 'الرمز لا يحتوي على رقم هاتف لمعرفة الحساب. تم رفض السند.';
  static const String theDefaultCostCenter = 'تعذر حفظ مركز التكلفة الافتراضي للحساب.';
  static const String jordanianDinar = 'دينار أردني';
  static const String costaRica = 'كوستاريكا';
  static const String updateOnTheBond = 'تحديث على السند';
  static const String confirmAndDecrypt = 'تأكيد وفك التشفير';
  static const String allowAccess = 'السماح بالوصول';
  static const String unableToUpdateNotification = 'تعذر تحديث حالة الإشعار.';
  static const String theAffectedPartyAnd = 'لا يمكن أن يكون الطرف والحساب المتأثر نفس الحساب في السند.';
  static const String alertMortgageDueDate = 'تنبيه: موعد استحقاق رهن';
  static const String skippedMovements = 'حركات متخطاة';
  static const String includedWithDigitalDocumentation = 'مشمول بالتوثيق الرقمي';
  static const String obligationsAndDebts = 'التزامات وديون';
  static const String receiptVoucher = 'سند قبض';
  static const String georgia = 'جورجيا';
  static const String sent = 'ارسلت';
  static const String expired = 'منتهي الصلاحية';
  static const String theSignatureDoesNot = 'التوقيع لا ينتمي إلى هذا الحساب. يبقى معلقاً كإدعاء لم يقم ذلك الحساب الطرف بالموافقة عليه.';
  static const String theBondIsWithdrawn = 'تم سحب السند من قبل صاحب السند';
  static const String moldova = 'مولدافيا';
  static const String noCounterpartyDataFound = 'لم يتم العثور على بيانات الطرف المقابل.';
  static const String whatsappBusiness = 'واتساب للأعمال';
  static const String sweden = 'السويد';
  static const String sourceQaidPersonalAccounting = 'المصدر: تطبيق قيد للمحاسبة الشخصية';
  static const String aNewDigitalIdentity = 'سيتم الآن إنشاء هوية رقمية جديدة لتأمين وتشفير بياناتك على هذا الجهاز.';
  static const String unableToDeleteAccount = 'تعذر حذف الحساب. قد يوجد حسابات فرعية أو حركات مرتبطة.';
  static const String aCollectionCenterFor = 'مركز تجميعي لتصنيف المصروفات الشخصية تلقائياً';
  static const String thereIsNoAccount = 'لا يوجد حساب مرتبط برقم الهاتف في الرمز. تم رفض السند.';
  static const String southKorea = 'كوريا الجنوبية';
  static const String bolivia = 'بوليفيا';
  static const String newCaledonia = 'كاليدونيا الجديدة';
  static const String arrestDocument = 'سند القبض';
  static const String swaziland = 'سوازيلاند';
  static const String financialBond = 'سند مالي';
  static const String obligationsAndDebts1 = 'الالتزامات والديون';
  static const String theInstrumentCannotBe = 'لا يمكن تعديل السند إلا إذا كان مسودة، مسحوباً، أو قيد انتظار موافقة الطرف الآخر.';
  static const String unableToReadRecent = 'تعذر قراءة السندات الأخيرة.';
  static const String jamaica = 'جامايكا';
  static const String requestToCreateA = 'طلب إنشاء حوالة';
  static const String thereIsAnAccount = 'يوجد حساب مسجل مسبقاً بالبريد الإلكتروني هذا.';
  static const String gabon = 'الغابون';
  static const String totalBalance = 'الرصيد الإجمالي: ';
  static const String bahrainiDinar = 'دينار بحريني';
  static const String restriction = 'قيد';
  static const String couldNotOpenThe = 'تعذر فتح تطبيق الرسائل.';
  static const String exchange = 'صرف';
  static const String referenceDataOptional = 'بيانات مرجعية (اختياري)';
  static const String stPierreAndMicolon = 'سانت بيير وميكولون';
  static const String privacyPolicyHasBeen = 'تم تحديث سياسة الخصوصية.';
  static const String venezuela = 'فنزويلا';
  static const String kenya = 'كينيا';
  static const String theAccountDoesNot = 'الحساب غير موجود.';
  static const String registrationDataFromThe = 'بيانات القيد - من حساب العميل:';
  static const String blockchainVerification = 'التوثيق الرقمي (Blockchain Verification):';
  static const String blockList = 'قائمة الحظر';
  static const String your = 'لكم';
  static const String typeOfFinancialTransaction = 'نوع الحركة المالية';
  static const String theUserCouldNot = 'تعذّر إضافة المستخدم للقائمة.';
  static const String syria = 'سوريا';
  static const String theDimensionCouldNot = 'تعذر حذف البُعد.';
  static const String invalidDataCheckThe = 'بيانات غير صالحة. تحقق من المدخلات وأعد المحاولة.';
  static const String makeASettlement = 'إجراء تسوية';
  static const String guadeloupe = 'جوادلوب';
  static const String kyrgyzstan = 'قيرغيزستان';
  static const String theTransferHasBeen = 'تم اعتماد الحوالة';
  static const String kosovo = 'كوسوفو';
  static const String egyptianPound = 'جنيه مصري';
  static const String theDefaultTemplateCannot = 'لا يمكن حذف القالب الافتراضي.';
  static const String confirmSelection = 'تأكيد الاختيار';
  static const String onYou = 'عليكم';
  static const String france = 'فرنسا';
  static const String whatsappIsNotInstalled = 'واتساب غير مثبت على هذا الجهاز.';
  static const String startByAddingYour = 'ابدأ بإضافة أول سند لك في النظام';
  static const String waitingForTheOther = 'بانتظار الطرف الآخر';
  static const String toConnectTwoDevices = 'لربط جهازين مباشرة عبر الشبكة المحلية دون إنترنت.';
  static const String equatorialGuinea = 'غينيا الاستوائية';
  static const String theConsolidatedBackupCould = 'تعذر حفظ النسخة الاحتياطية الموحدة في المسار المحدد.';
  static const String theBondCanOnly = 'يمكن تأكيد السند من حالة المسودة فقط.';
  static const String transportationAndMobility = 'النقل والتنقل';
  static const String saveTheDoubleConversion = 'حفظ التحويل المزدوج';
  static const String thisMortgageCannotBe = 'لا يمكن تسوية هذا الرهن — تمت تصفيته أو الإفراج عنه مسبقاً.';
  static const String accountsReceivableYours = 'ذمم مدينة (لك)';
  static const String theBondIsPreaccepted = 'السند مقبول مسبقاً.';
  static const String pleaseEnterAName = 'يرجى إدخال مسمى للأصل';
  static const String personalLiving = 'المعيشة الشخصية';
  static const String liechtenstein = 'ليختنشتاين';
  static const String antarctica = 'القارة القطبية الجنوبية';
  static const String unableToConnectTo = 'تعذّر الاتصال بالخادم. تحقق من اتصالك بالإنترنت.';
  static const String theEntityOriginatingThe = ':الجهة المُنشِئة للكشف';
  static const String theInternalTransactionWas = 'تم تسجيل المعاملة الداخلية بنجاح.';
  static const String confirmAndSend = 'تأكيد وإرسال';
  static const String amount = 'المبلغ';
  static const String balanced = 'متوازن';
  static const String serverErrorPleaseTry = 'خطأ في الخادم. يرجى المحاولة لاحقاً.';
  static const String unableToLoadComparison = 'تعذر تحميل بيانات المقارنة.';
  static const String healthAndPersonalCare = 'الصحة والعناية الشخصية';
  static const String mortgagePictures = 'صور الرهن';
  static const String restrictionsCannotBeCreated = 'لا يمكن إنشاء قيود لسند غير مؤكد.';
  static const String snapsync = 'مزامنة Snap-Sync';
  static const String notRegistered = 'غير مسجل';
  static const String errorLoadingTripleConversion = 'خطأ في تحميل بيانات التحويل الثلاثي.';
  static const String copyFromGoogleDrive = 'نسخة من Google Drive';
  static const String alderney = 'آلدرني';
  static const String unableToSearchBy1 = 'تعذر البحث بالبريد الإلكتروني.';
  static const String accountStatementConversation = 'محادثة كشف الحساب';
  static const String de = 'د.إ';
  static const String registrationDataDebitFrom = 'بيانات القيد (المدين) - من حساب العميل المرسل:';
  static const String costCenter = 'مركز التكلفة';
  static const String slovakia = 'سلوفاكيا';
  static const String italy = 'إيطاليا';
  static const String anUnexpectedErrorOccurred1 = 'حدث خطأ غير متوقع أثناء تهيئة الجهاز. يرجى المحاولة لاحقاً.';
  static const String couldNotUpdateThe = 'تعذّر تحديث القائمة.';
  static const String january = 'يناير';
  static const String notes = 'الملاحظات:';
  static const String unableToSaveThe = 'تعذر حفظ الإيصال المحدث.';
  static const String exportTheReport = 'تصدير التقرير';
  static const String replaceDatabaseUsingPrimary = 'فشل استبدال قاعدة البيانات باستخدام المفتاح الأساسي.';
  static const String anAccountWithA = 'لا يمكن إيقاف حساب له رصيد غير صفر.';
  static const String enterRecoveryPhraseHere = 'ادخل عبارة الاسترداد هنا...';
  static const String fromTheCustomersAccount = 'من حساب العميل:';
  static const String theDataHasBeen = 'تمت استعادة البيانات بنجاح.';
  static const String pleaseEnterYourFacility = 'يرجى إدخال معرف المنشأة ومفتاح التفعيل.';
  static const String bermuda = 'برمودا';
  static const String theTransferWasRejected = 'تم رفض الحوالة';
  static const String anErrorOccurredWhile = 'حدث خطأ أثناء معالجة بيانات الحساب.';
  static const String unableToReadVouchers = 'تعذر قراءة السندات لمركز التكلفة.';
  static const String theTemplateCouldNot = 'تعذر حذف القالب.';
  static const String previewTheReceipt = 'معاينة الإيصال';
  static const String theDimensionCouldNot1 = 'تعذر حفظ البُعد.';
  static const String displayTheBillOf = 'عرض سند الصرف';
  static const String reviewOutstandingBonds = 'مراجعة السندات المعلقة';
  static const String theTripleTransferVouchers = 'تعذر حفظ سندات التحويل الثلاثي. تم التراجع عن العملية.';
  static const String subscriptionHasExpiredPlease = 'انتهت صلاحية الاشتراك. يرجى سداد الرسوم لتفعيل التطبيق.';
  static const String internetConnectionFailedPlease = 'فشل الاتصال بالإنترنت، يرجى المحاولة لاحقاً.';
  static const String guinea = 'غينيا';
  static const String anAccountWithA1 = 'لا يمكن حذف حساب له رصيد غير صفر.';
  static const String yourBondHasBeen = 'تم قبول السند الخاص بك ومزامنته.';
  static const String boys = 'بنين';
  static const String singapore = 'سنغافورة';
  static const String algeria = 'الجزائر';
  static const String restoration = 'استعادة';
  static const String tajikistan = 'طاجيكستان';
  static const String yourGoogleAccountSignin = 'تم إلغاء أو فشل تسجيل الدخول إلى حساب Google.';
  static const String nextSteps = 'الخطوات التالية';
  static const String revenuesAndGains = 'إيرادات ومكاسب';
  static const String thisReportWasGenerated = 'تم إنشاء هذا التقرير بواسطة تطبيق قيد — Qayd App';
  static const String caymanIslands = 'جزر كايمان';
  static const String localCopyOnThe = 'نسخة محلية على الجهاز';
  static const String reportAProblem = 'الإبلاغ عن مشكلة';
  static const String theAccountIsTemporarily = 'الحساب موقوف مؤقتاً.';
  static const String selectCurrency = 'اختر العملة';
  static const String youHaveNotAdded = 'لم تقم بإضافة أي تحويلات وسيطة في هذا النظام بعد';
  static const String indonesia = 'إندونيسيا';
  static const String tunisia = 'تونس';
  static const String theAccount = 'الحساب';
  static const String failureToSaveThe = 'فشل في حفظ الرهن.';
  static const String accountTransactionsCouldNot = 'تعذر قراءة حركات الحساب.';
  static const String pleaseEnterThePrimary = 'الرجاء إدخال المفتاح الأساسي (كلمات الاسترداد الـ 24) لفك تشفير النسخة الاحتياطية.';
  static const String omani = '﷼ عماني';
  static const String beauvaisIsland = 'جزيرة بوفيه';
  static const String whatsappAndSmsMessage = 'قوالب رسائل الواتساب والـ SMS';
  static const String oweToYou = 'مدين (لك)';
  static const String liabilities = 'الخصوم — Liabilities';
  static const String resolvingConflicts = 'حسم التعارضات';
  static const String oman = 'عمان';
  static const String manIsland = 'مان (جزيرة)';
  static const String toMe = 'إلى:';
  static const String deposited = 'أودعت';
  static const String niue = 'نيوي';
  static const String headerSubdescription = 'الوصف الفرعي للترويسة';
  static const String japan = 'اليابان';
  static const String uganda = 'أوغندا';
  static const String bondsAreApprovedFrom = 'اعتمد السندات من قائمة الانتظار في التطبيق';
  static const String type = 'النوع';
  static const String theAccountHasBeen = 'تم إلغاء تفعيل الحساب من قِبل الإدارة.';
  static const String turksAndCaicosIslands = 'جزر توركس وكايكوس';
  static const String noticeOfDeductionFrom = 'إشعار بالخصم من الرصيد كتحويل مرسل';
  static const String failureToInspectMortgages = 'فشل في فحص الرهونات للسندات.';
  static const String daily = 'يومياً';
  static const String openWithBlocklist = 'مفتوح مع قائمة حظر';
  static const String estimatedValue = 'القيمة التقديرية';
  static const String unableToLoadContent = 'تعذر تحميل المحتوى.';
  static const String qatari = '﷼ قطري';
  static const String startByAddingYour1 = 'ابدأ بإضافة أول حساب لك في شجرة الحسابات';
  static const String russia = 'روسيا';
  static const String theAccounts = 'الحسابات';
  static const String withoutDescription = 'بدون وصف';
  static const String lesotho = 'ليسوتو';
  static const String thereAreNoTransfers = 'لا توجد تحويلات بعد';
  static const String chooseTheAppTo = 'اختر التطبيق للمشاركة';
  static const String descriptionOfTheMortgagesecurity = 'وصف الرهن / الضمان';
  static const String incomeAndWork = 'الدخل والعمل';
  static const String selectTheAppropriateTransfer = 'حدد طريقة التحويل المناسبة بين الأطراف';
  static const String myEditorialIsIndebted = 'افتتاحي مدين';
  static const String totalLiabilities = 'إجمالي الخصوم';
  static const String norfolkIsland = 'جزيرة نورفولك';
  static const String unableToCalculateCost = 'تعذر حساب مؤشرات مركز التكلفة.';
  static const String theBondCouldNot = 'تعذر فك ارتباط السند بمركز التكلفة.';
  static const String account = 'حساب';
  static const String mauritius = 'موريشيوس';
  static const String theDoubleConversionWas = 'تم حفظ التحويل المزدوج بنجاح';
  static const String file = 'ملف';
  static const String nature = 'طبيعة';
  static const String micronesia = 'ميكرونيزيا';
  static const String templateNotFound = 'القالب غير موجود.';
  static const String unableToCheckLicense = 'تعذر التحقق من حالة الترخيص. تحقق من الاتصال.';
  static const String manageAutomaticTextsWhen = 'إدارة النصوص التلقائية عند مشاركة السندات.';
  static const String anAccountWithA2 = 'لا يمكن أرشفة حساب له رصيد غير صفر. يجب تسوية الحساب أولاً.';
  static const String bondSettlementOnly = 'تسوية السند فقط';
  static const String northernMarianaIslands = 'جزر ماريانا الشمالية';
  static const String seychelles = 'سيشيل';
  static const String laos = 'لاوس';
  static const String openSettings = 'فتح الإعدادات';
  static const String monthly = 'شهرياً';
  static const String ledgerEntriesCouldNot = 'تعذر حفظ قيود دفتر الأستاذ.';
  static const String unableToSearchBonds = 'تعذر البحث في السندات.';
  static const String saintLucia = 'سانت لوسيا';
  static const String unableToUpdateSync = 'تعذر تحديث علامة المزامنة.';
  static const String pakistan = 'باكستان';
  static const String gramOfSilver = 'جرام فضة';
  static const String failedToDeleteThe = 'فشل في حذف المرفق.';
  static const String whatsapp = 'واتساب';
  static const String manageBlockList = 'إدارة قائمة الحظر';
  static const String failedToSaveSome = 'فشل في حفظ بعض المرفقات.';
  static const String gibraltar = 'جبل طارق';
  static const String total = 'الإجمالي';
  static const String autostring = 'تذكير: رهن يستحق قريباً';
  static const String noMatchingResultsFound = 'لا توجد نتائج مطابقة';
  static const String failedToUpdateLicense = 'فشل تحديث حالة الترخيص. تأكد من اتصالك بالإنترنت.';
  static const String theBondAmountMust = 'مبلغ السند يجب أن يكون أكبر من صفر.';
  static const String autostring1 = 'جزر كوكوس (كيلينغ)';
  static const String itPreventsEveryoneFrom = 'يمنع الجميع من المزامنة معك بشكل كامل.';
  static const String thereAreNoTransactions = 'لا توجد عمليات مسجلة في السجل حالياً';
  static const String congo = 'الكونغو';
  static const String signatureAgreement = 'اتفاق التوقيع';
  static const String autostring2 = 'التعليم وتنمية القدرات';
  static const String antiguaAndBarbuda = 'انتيغا وباربودا';
  static const String aruba = 'أروبا';
  static const String theUserHasBeen = 'تم إضافة المستخدم للقائمة.';
  static const String theListIsEmpty = 'القائمة فارغة';
  static const String unableToReadSubaccounts = 'تعذر قراءة الحسابات الفرعية.';
  static const String theMortgageHasBeen = 'تمت تسوية الرهن بنجاح ';
  static const String totalDebit = 'إجمالي المدين';
  static const String cellPhone = 'جوال';
  static const String buildingCFordCar = 'عمارة ج، سيارة فورد، محفظة الأسهم...';
  static const String thereAreNoNew = 'لا توجد إشعارات جديدة';
  static const String openToEveryone = 'مفتوح للجميع';
  static const String retry = 'إعادة المحاولة';
  static const String partialMatch = 'تطابق جزئي';
  static const String theBondHasBeen = 'تم سداد السند';
  static const String afghanistan = 'أفغانستان';
  static const String balance = 'الرصيد';
  static const String theSynchronizationTableCould = 'تعذر قراءة جدول المزامنة.';
  static const String updateOnTheTransfer = 'تحديث على الحوالة';
  static const String autostring3 = 'نظام قيد المالي';
  static const String released = 'تم الإفراج';
  static const String noFileWasFound = 'لم يتم العثور على ملف لاستعادته.';
  static const String closing = 'الختامي';
  static const String digitallySigned = ' موقّع رقمياً';
  static const String failedToDownloadMortgage = 'فشل في تحميل بيانات الرهن.';
  static const String autostring4 = 'قيد — Qayd App';
  static const String active = 'نشط';
  static const String financialReports = 'التقارير المالية';
  static const String suriname = 'سورينام';
  static const String ghana = 'غانا';
  static const String signInWithYour = 'سجل الدخول بحساب Google للبحث عن نسخة احتياطية';
  static const String assets = 'الأصول';
  static const String theDatabaseVersionIs = 'نسخة قاعدة البيانات غير مدعومة.';
  static const String movement = 'الحركة';
  static const String andorra = 'أندورا';
  static const String statement = 'البيان:';
  static const String uzbekistan = 'أوزبكستان';
  static const String barbados = 'باربادوس';
  static const String theAssetHasBeen = 'تم تسجيل الأصل وربطه بالدائرة الاقتصادية بنجاح.';
  static const String india = 'الهند';
  static const String closedToEveryone = 'مغلق عن الجميع';
  static const String unableToReadMonthly = 'تعذر قراءة البيانات الشهرية.';
  static const String transferFees = 'رسوم الحوالات';
  static const String updateAccountStatus = 'تحديث حالة الحساب';
  static const String noBondDataFound = 'لم يتم العثور على بيانات السندين.';
  static const String mauritania = 'موريتانيا';
  static const String signatureOfReceivingClient = '(توقيع العميل المستلم)';
  static const String november = 'نوفمبر';
  static const String addressingBondConflicts = 'معالجة تعارض السندات';
  static const String myAccountBroker = 'حسابي (وسيط)';
  static const String outgoingTransfer = 'حواله صادره';
  static const String theMediator = 'الوسيط';
  static const String falklandIslands = 'جزر فوكلاند';
  static const String automaticallyDetecting = 'جاري الكشف التلقائي…';
  static const String importAndFormat = 'استيراد وتهيئة';
  static const String errorTheAssetRoot = 'خطأ: لم يتم العثور على الحساب الجذر للأصول.';
  static const String confirmationDate = 'تاريخ التأكيد';
  static const String theFileIsEmpty = 'الملف فارغ.';
  static const String registrationNumberLocationSpecifications = 'رقم السجل، الموقع، المواصفات...';
  static const String ecuador = 'الإكوادور';
  static const String invalidResponseNoAuthentication = 'الرد غير صالح: لا يوجد رمز مصادقة.';
  static const String loading = 'جاري التحميل...';
  static const String natureOfAccount = 'طبيعة الحساب:';
  static const String s2 = '٢';
  static const String video = 'فيديو';
  static const String formatPdfFilesAnd = 'تنسيق ملفات الـ PDF والصور';
  static const String nauru = 'ناورو';
  static const String estonia = 'إستونيا';
  static const String february = 'فبراير';
  static const String labelTheNumberField = 'تسمية حقل الرقم';
  static const String waitingForApproval = 'بانتظار الموافقة';
  static const String cambodia = 'كمبوديا';
  static const String thereIsNoDebt = 'لا يوجد دين مستحق للتسوية.';
  static const String croatiaHrvatska = 'كرواتيا (هرفاتسكا)';
  static const String incoming = 'وارد';
  static const String unableToReadDependent = 'تعذر قراءة الحسابات التابعة.';
  static const String contactTechnicalSupport = 'تواصل مع الدعم الفني';
  static const String thereIsAPrevious = 'هناك نسخة احتياطية سابقة لبياناتك. هل تود استعادتها الآن؟';
  static const String bondsCanBeDeleted = 'يمكن حذف السندات في حالة المسودة فقط.';
  static const String bangladesh = 'بنغلادش';
  static const String aFinancialAccountAnd = 'سيتم إنشاء حساب مالي ومركز استثماري مرتبط بهذا الأصل مباشرة.';
  static const String theFundAccountWas = 'لم يتم العثور على حساب الصندوق تلقائياً';
  static const String anUnexpectedErrorOccurred2 = 'حدث خطأ غير متوقع أثناء إنشاء الحساب. يرجى المحاولة لاحقاً.';
  static const String iHaveAPrevious = 'لدي مفتاح سابق (24 كلمة) بالفعل';
  static const String debitDataFromThe = 'بيانات القيد (المدين) — من حساب المُرسِل:';
  static const String trialBalance = 'ميزان المراجعة';
  static const String actualSellingValue = 'قيمة البيع الفعلية';
  static const String backToThisPoint = 'تراجع لهذه النقطة';
  static const String signatureOfTheReceiving = 'توقيع الطرف المستلم';
  static const String theAccountStatusHas = 'حالة الحساب لم تتغير. يرجى التواصل مع الإدارة.';
  static const String thePartyDataCould = 'تعذر حفظ بيانات الطرف.';
  static const String brazil = 'البرازيل';
  static const String theFundAccountMust = 'حساب الصندوق يجب أن يكون مختلفاً عن المرسل والمستلم.';
  static const String theTemplateCouldNot1 = 'تعذر حفظ القالب.';
  static const String liberia = 'ليبيريا';
  static const String realEstateStocksMoneymaking = 'عقارات، أسهم، مشاريع تدر مالاً';
  static const String theMortgageDoesNot = 'الرهن غير موجود.';
  static const String theDocumentCannotBe = 'لا يمكن حذف السند أو ليس مسودة.';
  static const String failedToDownloadAttachments = 'فشل في تحميل المرفقات.';
  static const String exportPdf = 'تصدير PDF';
  static const String bear = 'د.ب';
  static const String theAccountDoesNot1 = 'الحساب غير موجود. لا يمكن التحقق من التوقيع.';
  static const String fingerprintsignaturesigsignaturessafaf0932128 = '(?:بصمة|توقيع|sig|signature)\\s*[:=]?\\s*([a-fA-F0-9]{32,128})';
  static const String anAccountThatHas = 'لا يمكن حذف حساب يملك حسابات فرعية.';
  static const String electronicSignature = 'التوقيع الإلكتروني';
  static const String thePartysOutboxCould = 'تعذر قراءة صندوق الصادر للطرف.';
  static const String unableToDeleteUser = 'تعذّر حذف المستخدم من القائمة.';
  static const String northKorea = 'كوريا الشمالية';
  static const String footerRightsText = 'نص حقوق التذييل';
  static const String theAttachmentDoesNot = 'المرفق غير موجود في قاعدة البيانات.';
  static const String colombia = 'كولومبيا';
  static const String jordan = 'الأردن';
  static const String debtor = 'مدين';
  static const String thePartyOriginatingThe = 'الجهة المُنشِئة للكشف:';
  static const String entryPersonalAccounting = 'قيد — المحاسبة الشخصية';
  static const String exhibition = 'المعرض';
  static const String theBondCannotBe = 'لا يمكن تأكيد السند حتى يتم توقيعه من قبلك أو من قبل الطرف الآخر.';
  static const String theAccountCouldNot = 'تعذر أرشفة الحساب.';
  static const String theDocumentCouldNot = 'تعذر قراءة السند.';
  static const String turkishLira = 'ليرة تركية';
  static const String unableToDeleteCost = 'تعذر حذف مركز التكلفة — قد تكون هناك سندات مرتبطة.';
  static const String aReturnCannotBe = 'لا يمكن إنشاء مرتجع لسند غير مؤكد.';
  static const String theUserHasBeen1 = 'تم حذف المستخدم من القائمة.';
  static const String referenceId = 'المعرف المرجعي:';
  static const String importCompleted = 'اكتمل الاستيراد';
  static const String belgium = 'بلجيكا';
  static const String newStr = 'جديد';
  static const String basic = 'الأساسية';
  static const String signatureOfTheOpposite = 'توقيع الطرف المقابل';
  static const String addAMortgagesecurity = 'إضافة رهن / ضمان';
  static const String loginDataIsIncorrect = 'بيانات الدخول غير صحيحة.';
  static const String confirmRollback = 'تأكيد التراجع';
  static const String dominicanRepublic = 'جمهورية الدومينيكان';
  static const String settlementType = 'نوع التسوية';
  static const String issued = 'صادر';
  static const String theLedgerCouldNot = 'تعذر قراءة دفتر الأستاذ.';
  static const String anonymousParty = 'طرف مجهول';
  static const String nnautomaticallyExportedViaThe = ']}.\\n\\nمُصدّر آلياً عبر نظام قيد المالي.';
  static const String unableToReadConversion = 'تعذر قراءة سندات مجموعة التحويل.';
  static const String reference = 'المرجع:';
  static const String pleaseEnterAValid = 'يرجى إدخال قيمة صحيحة للرهن';
  static const String liquidationOfMortgage = 'تصفية الرهن';
  static const String myCity = 'مديني';
  static const String nepal = 'نيبال';
  static const String theTransferRequestHas = 'تم إرسال طلب الحوالة للوسيط بنجاح';
  static const String financialAndPersonalSettlements = 'تسويات مالية وشخصية';
  static const String slovenia = 'سلوفينيا';
  static const String dutchCaribbeanIslands = 'الجزر الكاريبية الهولندية';
  static const String keypkpublickeyssafaf0932128 = '(?:مفتاح|pk|public_key)\\s*[:=]?\\s*([a-fA-F0-9]{32,128})';
  static const String december = 'ديسمبر';
  static const String creditOpening = 'افتتاحي دائن';
  static const String openingBalances = 'الأرصدة الافتتاحية';
  static const String recurringAmount = 'مبلغ متكرر';
  static const String qatar = 'قطر';
  static const String noBackupFoundIn = 'لم يتم العثور على نسخة احتياطية في Google Drive';
  static const String annually = 'سنوياً';
  static const String p2pSyncCodeSnapsync = 'رمز مزامنة P2P (Snap-Sync)';
  static const String saudiRiyals = '﷼ سعودي';
  static const String august = 'أغسطس';
  static const String unableToCreateOr = 'تعذر إنشاء أو مشاركة النسخة الاحتياطية الموحدة.';
  static const String grenada = 'غرينادا';
  static const String conversionSettings = 'إعدادات التحويل';
  static const String brokerTransferNotice = 'إشعار تحويل وسيط';
  static const String unableToReadArchived = 'تعذر قراءة الحسابات المؤرشفة.';
  static const String trinidadAndTobago = 'ترينيداد وتوباغو';
  static const String bonds = 'السندات';
  static const String southSudan = 'جنوب السودان';
  static const String classificationOfEconomicAsset = 'تصنيف الأصل الاقتصادي';
  static const String germany = 'ألمانيا';
  static const String noticeOfAdditionTo = 'إشعار بالإضافة إلى الرصيد كتحويل مستلم';
  static const String theDrawingObjectCould = 'تعذر الوصول إلى كائن الرسم';
  static const String automaticClassificationGeneration = 'توليد التصنيفات التلقائية';
  static const String centralAfricanRepublic = 'جمهورية أفريقيا الوسطى';
  static const String and = ' و ';
  static const String christmasIsland = 'جزيرة الكريسماس';
  static const String unableToReadPosition = 'تعذر قراءة استحقاقات المركز.';
  static const String tonga = 'تونغا';
  static const String theDefaultAccountCannot = 'لا يمكن أرشفة الحساب الافتراضي.';
  static const String balanceSheetRecordingSystem = 'الميزانية العمومية — نظام قيد';
  static const String outgoingTransfer1 = 'تحويل صادر';
  static const String listOfBondsTo = 'قائمة السندات التي سيتم استيرادها في وضع المسودة.';
  static const String makeAPaymentOn = 'سداد دفعة من الفاتورة الآجلة المستحقة رقم 452';
  static const String unbalanced = 'غير متوازن';
  static const String unableToDeleteAccount1 = 'تعذر حذف الحساب.';
  static const String missingValidity = 'صلاحية مفقودة';
  static const String partial = 'جزئي';
  static const String theBondCouldNot1 = 'تعذر حفظ السند.';
  static const String howDoesImportWork = 'كيف يعمل الاستيراد؟';
  static const String theMainFundAccount = 'تعذّر العثور على حساب الصندوق الرئيسي. تأكد من إعداد الحساب الافتراضي.';
  static const String acquisitionCurrency = 'عملة الاستحواذ';
  static const String save = 'حفظ';
  static const String creditorToYou = ' دائن (عليك)';
  static const String addAnAmounttoRecipients = 'إضافة مبلغ ... إلى حساب [المستلم]';
  static const String theEntitlementCouldNot = 'تعذر قراءة الاستحقاق.';
  static const String angola = 'أنغولا';
  static const String theAutomaticBackupCould = 'تعذر إنشاء النسخة الاحتياطية التلقائية.';
  static const String accountDetailsAccountnamencurrentBalance = 'تفاصيل الحساب: {{account_name}}\\nالرصيد الحالي: {{balance}}\\nطبيعة الحساب: {{nature}}\\nمعرّف الحساب: {{account_id}}\\n— قيد';
  static const String viewDetails = 'عرض التفاصيل';
  static const String sender = 'المرسل';
  static const String landIslands = 'جزر اولاند';
  static const String iDeposited = 'اودعت';
  static const String taiwan = 'تايوان';
  static const String dearCustomernweWouldLike = 'عزيزي {{customer}}،\\nنحيطكم علماً بأنه تم خصم مبلغ {{amount}} في سند {{type}} رقم: {{voucher_id}} بتاريخ {{date}}.\\nالرصيد الإجمالي: {{net_balance}}\\nالمرسل: {{sender_party}}\\nالمستلم: {{receiver_party}}\\nالبيان: {{description}}\\nالتوثيق: {{signature}}\\n— نظام قيد';
  static const String theBondDoesNot = 'السند غير موجود.';
  static const String unableToSaveAnd = 'تعذر حفظ ومزامنة سندات التحويل الثلاثي مع القيود.';
  static const String theFileDoesNot1 = 'الملف لا يحتوي على قاعدة بيانات قيد.';
  static const String incomingBondSync = 'السند الوارد (مزامنة)';
  static const String thePhilippines = 'الفلبين';
  static const String correctionAndRedirection = 'تصحيح وإعادة توجيه';
  static const String once = 'مرة واحدة';
  static const String theRequestHasBeen = 'تم إرسال الطلب بنجاح. سنراجع طلبك في أقرب وقت.';
  static const String dry = 'ج.ف';
  static const String czechRepublic = 'الجمهورية التشيكية';
  static const String thisBondHasBeen = 'تم سحب هذا السند. هل تريد تصحيح الوجهة وإعادة الإرسال؟';
  static const String montenegro = 'الجبل الأسود';
  static const String transferFeeIncome = 'إيراد رسوم التحويل';
  static const String solomonIslands = 'جزر سليمان';
  static const String hongKongSpecialAdministrative = 'هونغ كونغ (مناطق جمهورية الصين الشعبية الإدارية الخاصة)';
  static const String vietnam = 'فيتنام';
  static const String linkedBonds = 'السندات المرتبطة';
  static const String synchronizationControl = 'التحكم بالمزامنة';
  static const String frenchGuiana = 'غيانا الفرنسية';
  static const String uruguay = 'أوروغواي';
  static const String unknownAccount = 'حساب غير معروف';
  static const String bondApproval = 'اعتماد السندات';
  static const String theFreeTrialPeriod = 'انتهت فترة التجربة المجانية. يرجى التواصل مع الإدارة لتجديد الاشتراك.';
  static const String autostring5 = 'نحتاج للوصول لجهات الاتصال لمطابقة الأرقام وضمان سلامة التحويلات المالية وتوثيقها بشكل صحيح.';
  static const String chile = 'تشيلي';
  static const String nameOfOriginking = 'مسمى الأصل / الملك';
  static const String senderDeductedFromHis = 'المُرْسِل (يُخصم من حسابه)';
  static const String unableToOpenWhatsapp = 'تعذر فتح واتساب.';
  static const String peru = 'بيرو';
  static const String accountErasureIsA = 'محو الحساب هو إجراء نهائي يقوم بحذف كافة البيانات المالية والنسخ الاحتياطية من السيرفر ومن Google Drive ومن جهازك.';
  static const String mortgageLiquidationSurplusHeld = 'فائض تصفية رهن - محتجز لصالح العميل';
  static const String theEntryAmountMust = 'مبلغ القيد يجب أن يكون أكبر من صفر.';
  static const String noAccountBalancesWere = 'لم يتم العثور على أي أرصدة للحسابات في هذه الفترة';
  static const String papuaNewGuinea = 'بابوا غينيا الجديدة';
  static const String jersey = 'جيرسي';
  static const String bondNumber = 'رقم السند';
  static const String honduras = 'هندوراس';
  static const String costCenterDoesNot = 'مركز التكلفة غير موجود.';
  static const String unableToDeleteCost1 = 'تعذر حذف مركز التكلفة.';
  static const String unableToReadParty = 'تعذر قراءة سندات الطرف.';
  static const String period = 'الفترة:';
  static const String importingData = 'جاري استيراد البيانات...';
  static const String investmentsAndProjects = 'الاستثمارات والمشاريع';
  static const String montserrat = 'مونتسيرات';
  static const String syncingViaDirectQr = 'المزامنة عبر مسح باركود QR مباشرة تعتبر موافقة صريحة وتتجاوز هذه الإعدادات.';
  static const String description = 'الوصف';
  static const String yourLoginHasBeen = 'تم إلغاء تسجيل الدخول.';
  static const String finished = 'منتهي';
  static const String nigeria = 'نيجيريا';
  static const String outlyingIslandsOfThe = 'جزر الولايات المتحدة النائية';
  static const String myCreditors = 'دائني';
  static const String retainedSurplusForThe = 'فائض محتجز للعميل';
  static const String aBridgeBetweenSender = 'جسر بين المرسل والمستلم. الصندوق لا يتأثر ولا يظهر في المحادثات.';
  static const String companyName = 'اسم الشركة:';
  static const String recipientCreditedToHis = 'المُسْتلم (يُضاف لحسابه)';
  static const String openEachDocumentVerify = 'افتح كل سند وتحقق من البيانات ثم اعتمده';
  static const String june = 'يونيو';
  static const String cD = 'ج.ذ';
  static const String unableToSaveAccount = 'تعذر حفظ الحساب.';
  static const String checkTheBond = 'تحقق من السند';
  static const String selectAnyTextIn = 'اختر أي نص في المعاينة أعلاه للبدء بالتخصيص المباشر';
  static const String spain = 'إسبانيا';
  static const String denmark = 'الدانمارك';
  static const String heardIslandAndMcdonald = 'جزيرة هيرد وجزر ماكدونالد';
  static const String send = 'إرسال';
  static const String thankYouForDealing = 'شكراً لتعاملكم معنا!\\nيرجى مراجعة الأرصدة والتأكد من صحتها.';
  static const String khaledWalidAlamiri = 'خالد وليد العامري';
  static const String pleaseEnterACommit = 'يرجى إدخال اسم الالتزام.';
  static const String reviewTheAttachedPictures = 'استعراض الصور المرفقة';
  static const String receiptNotice = 'إشعار قبض';
  static const String tuvalu = 'توفالو';
  static const String manageCurrenciesAndVirtual = 'إدارة العملات والعملة الافتراضية للتطبيق.';
  static const String s3 = '٣';
  static const String financialReceiptVoucherPreview = 'سـنـد قـبـض مـالـي (مـعـايـنـة)';
  static const String nameOfTheOther = 'مسمى الطرف الآخر';
  static const String liquidateOfferForSale = 'Liquidate / عرض للبيع';
  static const String toWithdraw = 'سحب';
  static const String austria = 'النمسا';
  static const String kiribati = 'كيريباتي';
  static const String unableToSaveNotification = 'تعذر حفظ نص الإشعار للمقترحات.';
  static const String unableToLoadPrivacy = 'تعذّر تحميل إعدادات الخصوصية.';
  static const String malta = 'مالطا';
  static const String westernSahara = 'الصحراء الغربية';
  static const String importAnotherFile = 'استيراد ملف آخر';
  static const String faroeIslands = 'جزر فاروس';
  static const String theDefaultAccountCannot1 = 'لا يمكن إيقاف الحساب الافتراضي.';
  static const String aGramOfGold = 'جرام ذهب';
  static const String id = 'المعرّف';
  static const String belarus = 'بيلاروسيا';
  static const String accountId = 'معرّف الحساب';
  static const String greece = 'اليونان';
  static const String reviewAccountingEntries = 'مراجعة القيود المحاسبية';
  static const String jm = 'ج.م';
  static const String thisActionCannotBe = 'هذا الإجراء لا يمكن التراجع عنه';
  static const String kingdomOfSaudiArabia = 'المملكة العربية السعودية';
  static const String asNumtostringasfixed0Hour = '] as num).toStringAsFixed(0)} /ساعة';
  static const String automaticallyExportedAndDigitally = 'مُصدّر آلياً وموثق رقمياً عبر نظام قيد';
  static const String transferAmount = 'مبلغ التحويل';
  static const String reassessmentLog = 'سجل إعادة التقييم';
  static const String onlyUsersSpecifiedIn = 'يسمح فقط للمستخدمين المحددين في قائمة السماح.';
  static const String dearCustomernweWouldLike1 = 'عزيزي {{customer}}،\\nنحيطكم علماً بأنه تم استلام مبلغ {{amount}} في سند {{type}} رقم: {{voucher_id}} بتاريخ {{date}}.\\nالرصيد الإجمالي: {{net_balance}}\\nالمرسل: {{sender_party}}\\nالمستلم: {{receiver_party}}\\nالبيان: {{description}}\\nالتوثيق: {{signature}}\\n— نظام قيد';
  static const String theDoubleConversionFeature = 'خاصية التحويل المزدوج غير مفعلة.';
  static const String emiratiDirham = 'درهم إماراتي';
  static const String statementFieldName = 'مسمى حقل البيان';
  static const String unableToReadLabels = 'تعذر قراءة التصنيفات.';
  static const String cteDivoireIvoryCoast = 'كوت ديفوار (ساحل العاج)';
  static const String theCategoryCouldNot = 'تعذر حفظ التصنيف.';
  static const String theNameOfThe = 'لا يمكن تغيير اسم مركز التكلفة الافتراضي.';
  static const String virtualCostCenters = 'مراكز التكلفة الافتراضية';
  static const String addADefaultCost = 'إضافة مركز تكلفة افتراضي';
  static const String closingBalances = 'الأرصدة الختامية';
  static const String theDefaultCostCenter1 = 'لا يمكن إيقاف مركز التكلفة الافتراضي.';
  static const String unableToConnectTo1 = 'تعذر الاتصال بخدمات Google: يجب تكوين بصمة التطبيق (SHA-1) في إعدادات Firebase.';
  static const String macedonia = 'مقدونيا';
  static const String weekly = 'أسبوعياً';
  static const String classification = 'التصنيف';
  static const String remittanceClearing = 'مقاصة الحوالات';
  static const String noBackupOnDrive = 'لا توجد نسخة احتياطية على Drive.';
  static const String weFoundALocal = 'وجدنا نسخة احتياطية محلية، هل تريد استعادة بياناتك السابقة؟';
  static const String october = 'أكتوبر';
  static const String digitalAuditLog = 'سجل التدقيق الرقمي';
  static const String importModuleFromOld = 'وحدة الاستيراد من النظام القديم';
  static const String zambia = 'زامبيا';
  static const String deductingAnAmountfromThe = 'خصم مبلغ ... من حساب [المرسل]';
  static const String numberOfDecimalDigits = 'عدد الأرقام العشرية';
  static const String unknown = 'غير معروف';
  static const String eritrea = 'إريتريا';
  static const String guatemala = 'غواتيمالا';
  static const String theBondCannotBe1 = 'لا يمكن سحب السند بعد قبوله من الطرف الآخر أو تسويته.';
  static const String unitedArabEmirates = 'الإمارات العربية المتحدة';
  static const String azerbaijan = 'أذربيجان';
  static const String confirmFiltering = 'تأكيد التصفية';
  static const String quarterly = 'ربع سنوياً';
  static const String poland = 'بولندا';
  static const String capeVerde = 'الرأس الأخضر';
  static const String australia = 'أستراليا';
  static const String unableToReadAccrued = 'تعذر قراءة الاستحقاقات المستحقة.';
  static const String saintKittsAndNevis = 'سانت كيتس ونيفيس';
  static const String entitlementDoesNotExist = 'الاستحقاق غير موجود.';
  static const String uk = 'المملكة المتحدة';
  static const String notificationRecordNotFound = 'لم يُعثر على سجل الإشعار.';
  static const String sender1 = 'المُرسل';
  static const String failedToSaveRevaluation = 'فشل في حفظ سجل إعادة التقييم.';
  static const String disbursementNotice = 'إشعار صرف';
  static const String created0930Am04092026 = 'تم الإنشاء:  09:30 AM  09/04/2026';
  static const String catchDefaultTemplate = 'قبض — قالب افتراضي';
  static const String tanzania = 'تانزانيا';
  static const String theDefaultCostCenter2 = 'تعذر حذف مركز التكلفة الافتراضي من الحساب.';
  static const String panama = 'بنما';
  static const String theTransferHasBeen1 = 'تم سداد الحوالة';
  static const String clickToEdit = 'انقر للتعديل';
  static const String theCondition = 'الحالة';
  static const String mexico = 'المكسيك';
  static const String trialBalanceCryptocurrencySystem = 'Trial Balance — نظام السندات المالية المشفّرة';
  static const String yemeni = '﷼ يمني';
  static const String theCostCenterCould = 'تعذر قراءة مركز التكلفة.';
  static const String internetConnectionFailed = 'فشل الاتصال بالإنترنت';
  static const String toMerge = 'دمج';
  static const String egypt = 'مصر';
  static const String saveTheMortgage = 'حفظ الرهن';
  static const String openToMyAccounts = 'مفتوح لجهات حساباتي فقط';
  static const String exchangeDefaultTemplate = 'صرف — قالب افتراضي';
  static const String theCounterpartyHasRestricted = 'الطرف المقابل قيّد المزامنة مع حسابك.';
  static const String someDataCannotBe = 'بعض البيانات لا يمكن قراءتها بسبب اختلاف مفاتيح التشفير. جرب استعادة نسخة احتياطية محلية.';
  static const String macauSpecialAdministrativeRegions = 'ماكاو (مناطق جمهورية الصين الشعبية الإدارية الخاصة)';
  static const String balanced1 = 'متوازن ';
  static const String encryptionKeyRequired = 'مفتاح التشفير مطلوب';
  static const String dearCustomernweWouldLike2 = 'عزيزي {{customer}}،\\nنود إفادتكم بتسجيل إشعار قبض...\\nالتوقيع: {{signature}}';
  static const String marshallIslands = 'جزر مارشال';
  static const String unableToReadDouble = 'تعذر قراءة حركة مزدوجة القيد.';
  static const String submitTheRequest = 'إرسال الطلب';
  static const String importAndImmigration = 'الاستيراد والهجرة';
  static const String britishPounds = 'جنيه إسترليني';
  static const String theSendingAttemptCould = 'تعذر تسجيل محاولة الإرسال.';
  static const String failedToDownloadCopy = 'فشل تحميل النسخة من Drive.';
  static const String myConclusionIsIndebted = 'ختامي مدين';
  static const String brokerageTransferDetails = 'تفاصيل التحويل الوسيط';
  static const String youMustChooseA = 'يجب اختيار تصنيف قياسي أو تصنيف مخصص للحساب الجذر.';
  static const String failedToInquireAbout = 'فشل في استعلام الرهونات المستحقة.';
  static const String cryptocurrencySystem = 'نظام السندات المالية المشفّرة';
  static const String ukraine = 'أوكرانيا';
  static const String namibia = 'ناميبيا';
  static const String semiannually = 'نصف سنوياً';
  static const String requestANewFeature = 'طلب ميزة جديدة';
  static const String accountStatementASystem = 'Account Statement — نظام السندات المالية المشفّرة';
  static const String complete = 'مكتمل';
  static const String more = 'المزيد';
  static const String itIsNotPossible = 'لا يمكن إجراء عمليات حسابية بين عملتين مختلفتين.';
  static const String propertyRights = 'حقوق الملكية';
  static const String bondCouldNotBe = 'تعذر قراءة السندات.';
  static const String expensesAndConsumption = 'مصروفات واستهلاك';
  static const String dueDate = 'تاريخ الاستحقاق';
  static const String kuwaitiDinar = 'دينار كويتي';
  static const String importedAccount = 'حساب مستورد';
  static const String mainHeaderTitle = 'عنوان الترويسة الرئيسي';
  static const String previousCase = 'الحالة السابقة';
  static const String restrictedAllowListOnly = 'مقيّد — قائمة سماح فقط';
  static const String modifyingTheClassificationOr = 'تعديل التصنيف أو الحساب الأب قد يؤثر على توازن التقارير السابقة.';
  static const String movements = 'حركات';
  static const String savingAndBuildingReserves = 'الادخار وبناء الاحتياطي';
  static const String fundBroker = 'الصندوق (الوسيط)';
  static const String thePrivacyPolicyCould = 'تعذّر تحديث سياسة الخصوصية.';
  static const String usVirginIslands = 'جزر العذراء الأمريكية';
  static const String newAccount = 'حساب جديد';
  static const String transactionVouchersAreCreated = 'تنشأ سندات الحركات في حالة انتظار للمراجعة';
  static const String unableToReadMessage = 'تعذر قراءة قوالب الرسائل.';
  static const String thePartyDataCould1 = 'تعذر قراءة بيانات الطرف.';
  static const String southernRegionsOfFrance = 'المناطق الجنوبية لفرنسا';
  static const String sriLanka = 'سريلانكا';
  static const String allMovements = 'كل الحركات';
  static const String clickToChooseThe = 'اضغط لاختيار الوسيط';
  static const String theAmountCannotBe = 'لا يمكن أن يكون المبلغ سالباً.';
  static const String vanuatu = 'فانواتو';
  static const String cuba = 'كوبا';
  static const String missingBondInformationIn = 'بيانات السند المفقودة في الإشعار.';
  static const String almost = 'قريباً';
  static const String localRecord = 'سجل محلي';
  static const String netClosingBalances = 'صافي الأرصدة الختامية';
  static const String includingTransfers = 'منها تحويلات';
  static const String thisStatementWasGenerated = 'تم إنشاء هذا الكشف بواسطة تطبيق قيد — Qayd App';
  static const String saoTomeAndPrincipe = 'ساو تومي وبرينسيبي';
  static const String theFileCouldNot1 = 'تعذّر قراءة الملف.';
  static const String unableToUpdateDelivery = 'تعذر تحديث حالة التسليم.';
  static const String chronologyAndDependency = 'التسلسل الزمني والتبعية';
  static const String chad = 'تشاد';
  static const String basicCurrencySettings = 'إعدادات العملات الأساسية';
  static const String accountHolderData = 'بيانات صاحب الحساب';
  static const String unacceptable = 'مرفوض';
  static const String greenland = 'جرينلاند';
  static const String anErrorOccurred = 'حدث خطأ';
  static const String confirmAndRegisterThe = 'تأكيد وتسجيل الأصل في المحفظة';
  static const String netLiabilitiesAndOwnership = 'صافي الخصوم والملكية';
  static const String theHistoryOfAll = 'سيظهر هنا تاريخ كافة الحركات والعمليات التي تقوم بها';
  static const String unableToSearchFor = 'تعذر البحث عن الإيصالات المسودة.';
  static const String kuwait = 'الكويت';
  static const String aSettledBondIs = 'السند المسوّى غير قابل للتعديل.';
  static const String emailIsAlreadyRegistered = 'البريد الإلكتروني مسجّل مسبقاً.';
  static const String onlyUsersAllowedTo = 'المستخدمون المسموح فقط لهم بالمزامنة معك.';
  static const String theVoucherCouldNot = 'تعذر ربط السند بمركز التكلفة.';
  static const String liquidationOfMortgage1 = 'تصفية رهن';
  static const String requestToMakeA = 'طلب إجراء حوالة ثنائية الأطراف';
  static const String itAllowsAnyoneWith = 'يسمح لأي شخص لديه رقمك بمزامنة السندات معك.';
  static const String reviewEachAccountAnd = 'راجع كل حساب وحدّد كيفية التعامل معه. القرار الافتراضي مُعيَّن تلقائياً.';
  static const String amendment = 'تعديل';
  static const String newBond = 'سند جديد';
  static const String dearCustomer = 'عزيزي {{customer}}';
  static const String turkmenistan = 'تركمانستان';
  static const String balanceSheet = 'الميزانية العمومية';
  static const String allowList = 'قائمة السماح';
  static const String nutritionAndDailyConsumption = 'التغذية والاستهلاك اليومي';
  static const String implementationInProgress = 'جاري التنفيذ...';
  static const String anUnexpectedErrorOccurred3 = 'حدث خطأ غير متوقع.';
  static const String theEntitlementCouldNot1 = 'تعذر حذف الاستحقاق.';
  static const String releaseDate = 'تاريخ الإصدار:';
  static const String bhutan = 'بوتان';
  static const String closing1 = 'إغلاق';
  static const String latvia = 'لاتفيا';
  static const String securityWarning = 'تحذير الأمان';
  static const String periodMovement = 'حركة الفترة';
  static const String fullDebtSettlement = 'تسوية الدين الكامل';
  static const String theBondIsApproved = 'تم اعتماد السند من قبل الطرف الآخر';
  static const String theSourceAndDestination = 'لا يمكن أن يكون المصدر والوجهة نفس الطرف.';
  static const String ignoreIncomingDuplicate = 'تجاهل الوارد (مكرر)';
  static const String bondEntriesDoNot = 'قيود السند لا تطابق معرّف السند.';
  static const String adversaries = 'الخصوم';
  static const String restoreNow = 'استعادة الآن';
  static const String thereIsNoContent = 'لا يوجد محتوى متوفر حالياً.';
  static const String referenceNumber = 'رقم المرجع:';
  static const String attachPhotos = 'إرفاق صور';
  static const String theEntitlementCouldNot2 = 'تعذر حفظ الاستحقاق.';
  static const String addition = 'إضافة';
  static const String theAccountHasBeen1 = 'الحساب موقوف أو انتهت فترته التجريبية. تواصل مع المسؤول.';
  static const String labelTheDateField = 'تسمية حقل التاريخ';
  static const String readyToSync = 'جاهز للمزامنة';
  static const String importDataFromAn = 'استيراد بيانات من نظام قديم';
  static const String samoa = 'ساموا';
  static const String malaysia = 'ماليزيا';
  static const String toRequest = 'طلب';
  static const String failedToUpdateMortgage = 'فشل في تحديث الرهن.';
  static const String guineaBissau = 'غينيا بيساو';
  static const String thailand = 'تايلاند';
  static const String accounts = 'حسابات';
  static const String theBondHasBeen1 = 'تم سداد السند بالكامل';
  static const String cameraOrPhotos = 'الكاميرا أو الصور';
  static const String incomingTransfer = 'حواله وارده';
  static const String da = 'د.ا';
  static const String incomingTransfer1 = 'حوالة واردة';
  static const String theDatabaseFileCould = 'تعذر استبدال ملف قاعدة البيانات.';
  static const String confirmSystematicReversal = 'تأكيد التراجع النظامي';
  static const String choosePackageFileJson = 'اختر ملف الحزمة (.json)';
  static const String thereIsNoDatabase = 'لا توجد نسخة احتياطية لقاعدة البيانات على Drive.';
  static const String statement1 = 'البيان';
  static const String dominican = 'الدومينكان';
  static const String currency = 'العملة';
  static const String unableToReadCost = 'تعذر قراءة مراكز التكلفة المرتبطة بالسند.';
  static const String failedToSaveThe = 'فشل في حفظ المرفق.';
  static const String chooseFromContacts = 'اختر من جهات الاتصال';
  static const String debtSettlement = 'تسوية الدين';
  static const String tripleConversion = 'تحويل ثلاثي';
  static const String theBackupCouldNot = 'تعذر حفظ النسخة الاحتياطية في وحدة التخزين الخارجية.';
  static const String youHaveNotAdded1 = 'لم تقم بإضافة أي تدفقات مالية بعد';
  static const String acceptedAndSigned = 'مقبول وموقّع';
  static const String cyprus = 'قبرص';
  static const String eastTimor = 'تيمور الشرقية';
  static const String searchInGoogleDrive = 'البحث في Google Drive';
  static const String nautomaticallyExportedAndDigitally = '\\nمُصدّر آلياً وموثق رقمياً عبر نظام قيد المالي.';
  static const String currencySymbolExampleUsd = 'رمز العملة (مثال: USD)';
  static const String theNext = 'التالي';
  static const String familyAndDependents = 'الأسرة والمعالون';
  static const String albania = 'ألبانيا';
  static const String usDollars = 'دولار أمريكي';
  static const String parsingThePackage = 'جاري تحليل الحزمة...';
  static const String updateError = 'خطأ في التحديث';
  static const String privacyMode = 'وضع الخصوصية';
  static const String accountingRecordingSystem = 'نظام قيد المحاسبي';
  static const String southGeorgia = 'جورجيا الجنوبية';
  static const String accountAnalysis = 'تحليل الحسابات';
  static const String theDate = 'التاريخ';
  static const String theBondHasBeen2 = 'تم سحب السند';
  static const String sharingOptions = 'خيارات المشاركة';
  static const String detailedStatement = 'البيان التفصيلي:';
  static const String reviewAndConfirm = 'مراجعة وتأكيد';
  static const String paraguay = 'باراغواي';
  static const String unableToSearchBy2 = 'تعذر البحث برقم واتساب.';
  static const String creationDate = 'تاريخ الإنشاء';
  static const String customizeBondIdentity = 'تخصيص هوية السندات';
  static const String activationDataIsIncorrect = 'بيانات التفعيل غير صحيحة.';
  static const String identifyAndMatchDuplicate = 'تحديد الحسابات المكررة ومطابقتها';
  static const String bruneiDarussalam = 'بروناي دار السلام';
  static const String theDimensionsOfThe = 'تعذر قراءة أبعاد السند.';
  static const String chooseHowToShare = 'اختر طريقة المشاركة';
  static const String editor = 'محرر';
  static const String anguilla = 'أنغويلا';
  static const String zimbabwe = 'زمبابوي';
  static const String martinique = 'مارتينيك';
  static const String createANewIdentity = 'إنشاء هوية جديدة';
  static const String elSalvador = 'السلفادور';
  static const String theRestoreOperationFailed = 'فشل عملية الاستعادة.';
  static const String clickAnyColoredText = 'قم بالنقر على أي عنصر نصي ملون في المعاينة لتعديله';
  static const String googleLoginFailed = 'فشل تسجيل الدخول إلى Google';
  static const String sierraLeone = 'سيراليون';
  static const String affectedAccount = 'الحساب المتأثر';
  static const String unableToExtractImage = 'تعذر استخراج بيانات الصورة';
  static const String failedToLoadRevaluation = 'فشل في تحميل سجل إعادة التقييم.';
  static const String myanmar = 'ميانمار';
  static const String chooseADateOptional = 'اختر تاريخ (اختياري)';
  static const String theTemplateCouldNot2 = 'تعذر قراءة القالب.';
  static const String entertainmentAndLifestyle = 'الترفيه ونمط الحياة';
  static const String deposit1 = 'ايداع';
  static const String bahamas = 'جزر البهاماس';
  static const String personalExpenses = 'مصروفات شخصية';
  static const String searchForTheCountry = 'ابحث عن الدولة (بالعربية أو الإنجليزية)';
  static const String rs = 'ر.س';
  static const String customizeVisualIdentityLogo = 'تخصيص الهوية البصرية، الشعار، والنصوص المطبوعة.';
  static const String failedToDeleteBond = 'فشل في حذف مرفقات السند.';
  static const String saintVincentAndThe = 'سانت فينسنت وجزر غرينادين';
  static const String aPossibleMatchHas = 'لقد تم العثور على تطابق محتمل بين مسودة قمت بإنشائها وسند وارد من طرف آخر. كيف ترغب في المتابعة؟';
  static const String mayotte = 'مايوت';
  static const String assets1 = 'الأصول — Assets';
  static const String creditMovement = 'حركة دائن';
  static const String trySearchingWithOther1 = 'جرب البحث بكلمات أخرى';
  static const String enterNewTextHere = 'أدخل النص الجديد هنا...';
  static const String malawi = 'مالاوي';
  static const String filterTheFinancialRecord = 'تصفية السجل المالي';
  static const String theSystemWillCancel = 'سيقوم النظام بإلغاء كافة العمليات التي تمت بعد هذه اللحظة الزمنية وإعادة التطبيق إلى حالته حينها. هل ترغب بالمتابعة؟';
  static const String filtered = 'تمت التصفية';
  static const String anErrorOccurredWhile1 = 'حدث خطأ أثناء تصدير Excel';
  static const String thisNoticeIsConsidered = 'يُعتبر هذا الإشعار توثيقاً رسمياً بالإضافة إلى حساب المُستلِم.';
  static const String trkiye = 'تركيا';
  static const String saintMartinFrenchPart = 'سانت مارتن (الجزء الفرنسي)';
  static const String reunion = 'ريونيون';
  static const String aConfirmedOrSettled = 'لا يمكن رفض سند مؤكد أو مسوّى.';
  static const String s4 = '٤';
  static const String referenceNumber1 = 'الرقم المرجعي';
  static const String newNotification = 'إشعار جديد';
  static const String unexpectedErrorTryAgain = 'خطأ غير متوقع. حاول مرة أخرى.';
  static const String alnasserExchangeAndTransfers = 'شركة الناصر للصرافة والتحويلات';
  static const String canada = 'كندا';
  static const String outgoingTransfer2 = 'حوالة صادرة';
  static const String theSelectedCurrencyIs = 'العملة المختارة غير صالحة.';
  static const String twoVouchersWillBe = 'سيتم إنشاء سندين: سند خصم من المرسل وسند إضافة للمستلم.\\nالصندوق يتأثر برصيده.';
  static const String importedBonds = 'سندات مستوردة';
  static const String sintMaartenDutchPart = 'سينت مارتن (الجزء الهولندي)';
  static const String filterByCostCenter = 'تصفية حسب مركز التكلفة';
  static const String theOtherParty = 'الطرف الآخر';
  static const String failedToChargeMortgage = 'فشل في تحميل الرهن.';
  static const String regularbilateralBond = 'سند عادي / ثنائي';
  static const String activationCouldNotBe = 'تعذر إكمال التفعيل. حاول مرة أخرى.';
  static const String notes1 = 'الملاحظات';
  static const String theName = 'الاسم';
  static const String newConversion = 'تحويل جديد';
  static const String thePictures = 'الصور';
  static const String trialBalanceARecording = 'ميزان المراجعة — نظام قيد';
  static const String britishIndianOceanTerritory = 'إقليم المحيط البريطاني الهندي';
  static const String theBackupCouldNot1 = 'تعذر مشاركة النسخة الاحتياطية.';
  static const String theBondCanBe = 'يمكن تسوية السند من حالة التأكيد فقط.';
  static const String adoption = 'اعتماد';
  static const String watts = 'واتس';
  static const String theBondHasBeen3 = 'تم اعتماد السند';
  static const String lithuania = 'ليتوانيا';
  static const String balanceSheetCryptocurrencySystem = 'Balance Sheet — نظام السندات المالية المشفّرة';
  static const String nicaragua = 'نيكاراغوا';
  static const String theDate1 = 'التاريخ:';
  static const String matchingBondWouldYou = 'سند مطابق — هل ترغب في دمج هذا السند مع المسودة المحلية؟';
  static const String pleaseSignInTo = 'يرجى تسجيل الدخول إلى حساب Google أولاً.';
  static const String draft = 'مسودة';
  static const String da1 = 'د.أ';
  static const String unableToReadCost1 = 'تعذر قراءة مراكز التكلفة.';
  static const String str1 = '؟';
  static const String required = 'مطلوب';
  static const String theCounterpartysPublicKey = 'تعذر الحصول على المفتاح العام للطرف المقابل. تم تعليق المزامنة.';
  static const String ahmedKamalAlNasser = 'أحمد كمال الناصر';
  static const String theConnectionTimedOut = 'انتهت مهلة الاتصال. تحقق من اتصالك بالإنترنت.';
  static const String rightsAndEntitlements = 'حقوق ومستحقات';
  static const String palau = 'بالاو';
  static const String serbia = 'صربيا';
  static const String phoneNumberRequired = 'رقم الهاتف مطلوب';
  static const String theBondCouldNot2 = 'تعذر حذف السند.';
  static const String weFoundABackup = 'وجدنا نسخة احتياطية';
  static const String theEntryCouldNot = 'تعذر حفظ الإدخال في صندوق الصادر.';
  static const String britishVirginIslands = 'جزر العذراء البريطانية';
  static const String youMustSelectThe = 'يجب اختيار الدولة';
  static const String fixedAssetsProfitable = 'أصول ثابتة (ربحية)';
  static const String bondConflict = 'تعارض في السندات';
  static const String iraq = 'العراق';
  static const String neutral = 'متعادل';
  static const String accountId1 = 'هوية الحساب';
  static const String saintHelena = 'سانت هيلينا';
  static const String onlyPeopleOnYour = 'يسمح فقط لمن هم في جهات حساباتك بالمزامنة معك.';
  static const String luxembourg = 'لوكسمبورغ';
  static const String guyana = 'غيانا';
  static const String theCostCenterCould1 = 'تعذر حفظ مركز التكلفة.';
  static const String bosniaAndHerzegovina = 'البوسنة والهرسك';
  static const String chooseYourIncomeSource = 'اختر مصدر الدخل أو الأصل';
  static const String theFirstRowMust = 'يجب أن يحتوي الصف الأول على عمود باسم «name» أو «اسم».';
  static const String sudan = 'السودان';
  static const String senegal = 'السنغال';
  static const String mozambique = 'موزمبيق';
  static const String yemen = 'اليمن';
  static const String noValidDataRows = 'لم يُعثر على صفوف بيانات صالحة.';
  static const String sanMarino = 'سان مارينو';
  static const String uncertain = 'غير مؤكد';
  static const String camera = 'الكاميرا';
  static const String theFileDoesNot2 = 'الملف لا يحتوي على جداول قيد متوقعة.';
  static const String burundi = 'بوروندي';
  static const String unableToRestoreAccount = 'تعذر استعادة الحساب من الأرشيف.';
  static const String kazakhstan = 'كازاخستان';
  static const String waiting = 'انتظار';
  static const String guam = 'غوام';
  static const String theAccountCannotBe = 'لا يمكن نقل الحساب إلى أصل بتصنيف أو طبيعة مختلفة.';
  static const String from = 'من:';
  static const String reevaluate = 'إعادة تقييم';
  static const String theDefaultAccountCannot2 = 'لا يمكن حذف الحساب الافتراضي.';
  static const String excelExport = 'تصدير Excel';
  static const String financial = 'مالي';
  static const String theIntermediateAccountMust = 'الحساب الوسيط يجب أن يكون مختلفاً عن المصدر والوجهة.';
  static const String libya = 'ليبيا';
  static const String cancellation = 'إلغاء';
  static const String bondWasDenied = 'تم رفض السند';
  static const String july = 'يوليو';
  static const String skip = 'تخطي';
  static const String totalBalance1 = 'الرصيد الإجمالي';
  static const String signatureOfSendingClient = '(توقيع العميل المرسل)';
  static const String perfectMatch = 'تطابق تام';
  static const String theDefaultCostCenters = 'تعذر قراءة مراكز التكلفة الافتراضية للحساب.';
  static const String southAfrica = 'جنوب أفريقيا';
  static const String brokerConversion = 'تحويل وسيط';
  static const String totalCredit = 'إجمالي الدائن';
  static const String intermediateConversionTriple = 'تحويل وسيط (ثلاثي)';
  static const String nameOfTheFinancial = 'اسم الوسيط المالي';
  static const String may = 'مايو';
  static const String september = 'سبتمبر';
  static const String pleaseEnterTheName = 'يرجى إدخال اسم مركز التكلفة.';
  static const String haiti = 'هايتي';
  static const String secondClientSignature = '(توقيع العميل الثاني)';
  static const String accountBalanceDefaultTemplate = 'رصيد حساب — قالب افتراضي';
  static const String unableToReadTemplates = 'تعذر قراءة القوالب.';
  static const String tripleTransferDeedNotice = 'سند تحويل ثلاثي — إشعار للطرفين';
  static const String linkToRootAccount = 'ربط بالحساب الجذر:';
  static const String personalRevenue = 'إيرادات شخصية';
  static const String kwd = 'د.ك';
  static const String itWasNotPossible = 'تعذر تأكيد السند وحفظ القيود. تم التراجع عن العملية.';
  static const String nTheAuthenticityOf = '\\n-- تم التحقق من صحة التواقيع عبر نظام قيد --';
  static const String maldives = 'جزر المالديف';
  static const String april = 'أبريل';
  static const String monaco = 'موناكو';
  static const String holland = 'هولندا';
  static const String totalBalance2 = 'الرصيد الإجمالي:';
  static const String showTheReceiptDocument = 'عرض سند القبض';
  static const String mergeAndConfirmLocal = 'دمج وتأكيد المحلي';
  static const String addANewCurrency = 'إضافة عملة جديدة';
  static const String scanThisCodeFrom = 'امسح هذا الرمز من الجهاز الآخر لبدء المزامنة المباشرة عالية السرعة.';
  static const String accountName1 = 'اسم الحساب:';
  static const String skipAndStartWith = 'تخطي والبدء بجهاز جديد';
  static const String undefined = 'غير محدد';
  static const String editorial = 'الافتتاحي';
  static const String theSenderAndRecipient1 = 'لا يمكن أن يكون المرسل والمستلم نفس الطرف';
  static const String lebanon = 'لبنان';
  static const String iceland = 'أيسلندا';
  static const String tokelau = 'توكيلاو';
  static const String billOfExchange1 = 'سند الصرف';
  static const String itWasNotPossible1 = 'تعذر البحث عن السند المقابل.';
  static const String unableToReadReturns = 'تعذر قراءة سندات المرتجعات والتسويات.';
  static const String rwanda = 'رواندا';
  static const String democraticRepublicOfThe = 'جمهورية الكونغو الديمقراطية';
  static const String failedToLoadMortgages = 'فشل في تحميل الرهونات.';
  static const String pleaseEnterTheCategory = 'يرجى إدخال اسم التصنيف.';
  static const String unableToCreateAccount = 'تعذر إنشاء ملف كشف الحساب.';
  static const String ethiopia = 'إثيوبيا';
  static const String theAmountMustBe = 'يجب أن يكون المبلغ أكبر من صفر.';
  static const String aConfirmedOrSettled1 = 'لا يمكن إعادة عرض سند مؤكد أو مسوّى.';
  static const String other = 'أخرى';
  static const String fijiIslands = 'جزر فيجي';
  static const String theAccountCouldNot1 = 'تعذر قراءة الحساب من قاعدة البيانات.';
  static const String netBalance = 'الرصيد الصافي';
  static const String wallisAndFutuna = 'واليس وفوتونا';
  static const String switzerland = 'سويسرا';
  static const String phone = 'هاتف';
  static const String aGramOfSilver = 'جرام فضه';
  static const String ipDiscoveringNetwork = 'IP: (جارٍ اكتشاف الشبكة…)';
  static const String theConflictWasSuccessfully = 'تمت معالجة التعارض بنجاح.';
  static const String equity = 'حقوق الملكية — Equity';
  static const String trySearchingWithOther2 = 'جرب البحث بكلمات أخرى أو تغيير التصنيف';
  static const String unableToLoadNotification = 'تعذر تحميل مقترحات الإشعارات.';
  static const String sent1 = 'أرسلت';
  static const String thisNoticeIsConsidered1 = 'يُعتبر هذا الإشعار توثيقاً رسمياً بالخصم من حساب المُرسِل.';
  static const String theOutboxCouldNot = 'تعذر قراءة صندوق الصادر.';
  static const String creditClosing = 'ختامي دائن';
  static const String mongolia = 'منغوليا';
  static const String mortgageDetails = 'تفاصيل الرهن';
  static const String march = 'مارس';
  static const String bulgaria = 'بلغاريا';
  static const String ireland = 'أيرلندا';
  static const String theNameOfThe1 = 'اسم العملة بالعربية';
  static const String name = 'اسم';
  static const String activationHasExpiredPlease = 'انتهت صلاحية التفعيل. يرجى إدخال بيانات التفعيل من جديد.';
  static const String newBrokerageTransfer = 'حوالة وساطة جديدة';
  static const String accountsPayableYouOwe = 'ذمم دائنة (عليك)';
  static const String theBox = 'الصندوق';
  static const String twoOrdinaryBondsAffect = 'سندان عاديان يتأثر بهما الصندوق: خصم من المرسل وإضافة للمستلم.';
  static const String recordingDataCreditTo = 'بيانات القيد (الدائن) — إلى حساب المُستلِم:';
  static const String selectTheApprovedFinancial = 'حدد الوسيط المالي المعتمد';
  static const String withdrawdelete = 'سحب/حذف';
  static const String chooseExpenseOrTrade = 'اختر حساب المصروف أو التجارة';
  static const String morocco = 'المغرب';
  static const String aBondThatHas = 'لا يمكن سحب سند تم قبوله من الطرف الآخر أو تمت تسويته.';
  static const String unavailable = 'غير متوفر';
  static const String nature1 = 'الطبيعة';
  static const String romania = 'رومانيا';
  static const String vatican = 'الفاتيكان';
  static const String armenia = 'أرمينيا';
  static const String yourLocalRecordDraft = 'سجلك المحلي (مسودة)';
  static const String saintBarthelemy = 'سانت بارتيليمي';
  static const String thePrimaryKeyIs = 'المفتاح الأساسي غير صحيح أو لا ينتمي لهذه النسخة.';
  static const String catchStr = 'قبض';
  static const String comoros = 'جزر القمر';
  static const String requestToApproveA = 'طلب اعتماد سند';
  static const String root = 'جذر';
  static const String madianMovement = 'حركة مدين';
  static const String sar = 'ريال';
  static const String firstCustomerSignature = '(توقيع العميل الأول)';
  static const String hungary = 'هنغاريا';
  static const String signatureOfTheBond = 'توقيع مُصدر السند';
  static const String manageTheAllowList = 'إدارة قائمة السماح';
  static const String occupiedPalestinianTerritories = 'الأراضي الفلسطينية المحتلة';
  static const String theTransferHasBeen2 = 'تم سحب الحوالة';
  static const String back = 'رجوع';
  static const String us = 'الولايات المتحدة';
  static const String djibouti = 'جيبوتي';
  static const String toTreat = 'معالجة';
  static const String argentina = 'الأرجنتين';
  static const String sharingAcrossTheSystem = 'المشاركة عبر النظام';
  static const String pleaseEnterTheFull = 'الرجاء إدخال رمز التحقق بالكامل.';
  static const String unableToVerifyAccount = 'تعذر التحقق من وجود الحساب.';
  static const String theRootAccountFor = 'لم يتم العثور على الحساب الجذري للمصروفات الشخصية.';
  static const String belize = 'بليز';
  static const String carFurniturePersonalItems = 'سيارة، أثاث، أدوات شخصية';
  static const String norway = 'النرويج';
  static const String totalAssets = 'إجمالي الأصول';
  static const String pleaseSelectASender = 'الرجاء اختيار المرسل والمستلم';
  static const String bondsCreatedInPending = 'تم إنشاء السندات في حالة انتظار — راجعها واعتمدها';
  static const String searchForConversionDetails = 'بحث بتفاصيل التحويل...';
  static const String approved = 'تم الاعتماد';
  static const String bondNumber1 = 'رقم السند:';
  static const String recipient = 'المستلم';
  static const String newZealand = 'نيوزيلندا';
  static const String china = 'الصين';
  static const String decryptingImages = 'جاري فك تشفير الصور...';
  static const String entitlementsCouldNotBe = 'تعذر قراءة الاستحقاقات.';
  static const String unableToLoadInbox = 'تعذر تحميل إشعارات الصندوق الوارد.';
}
