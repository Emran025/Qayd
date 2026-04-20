import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';

class PdfTemplateSettingsPage extends StatefulWidget {
  const PdfTemplateSettingsPage({super.key});

  @override
  State<PdfTemplateSettingsPage> createState() =>
      _PdfTemplateSettingsPageState();
}

class _PdfTemplateSettingsPageState extends State<PdfTemplateSettingsPage> {
  // Brand Configuration
  final Map<String, String> _config = {
    'pdf_header_title': 'قيد — المحاسبة الشخصية',
    'pdf_header_subtitle': 'نظام السندات المالية المشفّرة',
    'pdf_label_voucher_no': 'رقم السند:',
    'pdf_label_date': 'التاريخ:',
    'pdf_label_from': 'من حساب العميل:',
    'pdf_label_description': 'البيان التفصيلي:',
    'pdf_footer_text': 'المصدر: تطبيق قيد للمحاسبة الشخصية',
    'pdf_mediator_name': 'شركة الناصر للصرافة والتحويلات',
  };

  String? _selectedKey;
  late TextEditingController _editController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = InjectionContainer.sharedPreferences;
    setState(() {
      for (var key in _config.keys) {
        _config[key] = prefs.getString(key) ?? _config[key]!;
      }
      _isLoading = false;
    });
  }

  Future<void> _saveCurrent() async {
    if (_selectedKey == null) return;
    final val = _editController.text.trim();
    if (val.isEmpty) return;

    await InjectionContainer.sharedPreferences.setString(_selectedKey!, val);
    setState(() {
      _config[_selectedKey!] = val;
    });
    FocusScope.of(context).unfocus();
  }

  void _selectField(String key) {
    setState(() {
      _selectedKey = key;
      _editController.text = _config[key]!;
    });
  }

  String _labelForKey(String key) {
    return switch (key) {
      'pdf_header_title' => 'عنوان الترويسة الرئيسي',
      'pdf_header_subtitle' => 'الوصف الفرعي للترويسة',
      'pdf_label_voucher_no' => 'تسمية حقل الرقم',
      'pdf_label_date' => 'تسمية حقل التاريخ',
      'pdf_label_from' => 'مسمى الطرف الآخر',
      'pdf_label_description' => 'مسمى حقل البيان',
      'pdf_footer_text' => 'نص حقوق التذييل',
      'pdf_mediator_name' => 'اسم الوسيط المالي',
      _ => key,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final gold = theme.extension<QaydCustomColors>()!.goldAccent;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        appBar: QaydAppBar(
          title: 'تخصيص هوية السندات',
          bottom: TabBar(
            tabs: const [
              Tab(text: 'سند عادي / ثنائي'),
              Tab(text: 'تحويل ثلاثي'),
            ],
            indicatorColor: gold,
            labelColor: gold,
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Normal Layout
                  _buildPreviewTab(isTripartite: false),
                  // Tab 2: Tripartite Layout
                  _buildPreviewTab(isTripartite: true),
                ],
              ),
            ),

            // ── EDITING PANEL ────────────────────────────────────────────────
            _buildBottomActionPanel(gold, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewTab({required bool isTripartite}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          const QaydText(
            'قم بالنقر على أي عنصر نصي ملون في المعاينة لتعديله',
            slot: QaydTextStyleSlot.labelSmall,
          ),
          const SizedBox(height: 24),
          Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Container(
                width: 550,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Center(
                          child: Opacity(
                            opacity: 0.05,
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 250,
                              height: 250,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildExactHeader(),
                          _buildExactTitleRow(isTripartite: isTripartite),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                _buildExactEntrySection(
                                  isTripartite: isTripartite,
                                  sectionType: 'debit',
                                ),
                                if (isTripartite) ...[
                                  const SizedBox(height: 8),
                                  _buildExactEntrySection(
                                    isTripartite: isTripartite,
                                    sectionType: 'credit',
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildExactSignatures(
                                isTripartite: isTripartite),
                          ),
                          const SizedBox(height: 12),
                          _buildExactFooter(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionPanel(Color gold, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 15,
              offset: const Offset(0, -5))
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedKey != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: gold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child:
                          Icon(Icons.edit_note_rounded, color: gold, size: 24),
                    ),
                    const SizedBox(width: 12),
                    QaydText(
                      'جاري تعديل: ${_labelForKey(_selectedKey!)}',
                      slot: QaydTextStyleSlot.bodyMedium,
                      color: theme.colorScheme.onSurface,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(() => _selectedKey = null),
                    )
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: TextField(
                  controller: _editController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'أدخل النص الجديد هنا...',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    suffixIcon: Container(
                      margin: const EdgeInsets.all(6),
                      child: ElevatedButton(
                        onPressed: _saveCurrent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          foregroundColor: const Color(0xFF0F2741),
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(60, 40),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('حفظ'),
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _saveCurrent(),
                ),
              ),
              const SizedBox(height: 12),
            ] else
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app_rounded, color: gold, size: 24),
                    const SizedBox(width: 12),
                    const QaydText(
                      'اختر أي نص في المعاينة أعلاه للبدء بالتخصيص المباشر',
                      slot: QaydTextStyleSlot.bodyMedium,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── PREVIEW COMPONENT BUILDERS (MATCHING VOUCHER_IMAGE_EXPORT EXACTLY) ─────

  Widget _buildExactHeader() {
    return Container(
      color: const Color(0xFFE8EDF3), // _headerBg
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _selectableText('pdf_header_title', 12, const Color(0xFF0F2741),
                    bold: true),
                const SizedBox(height: 2),
                _selectableText(
                    'pdf_header_subtitle', 8, const Color(0xFF64748B)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage('assets/images/logo.png'),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _directText(
                    'Qayd — Personal Accounting', 9, const Color(0xFF0F2741),
                    bold: true, dir: TextDirection.ltr),
                const SizedBox(height: 2),
                _directText('Encrypted Financial Voucher System', 7,
                    const Color(0xFF64748B),
                    dir: TextDirection.ltr),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExactTitleRow({required bool isTripartite}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _borderedBox('pdf_label_voucher_no', '2026-0034'),
              _borderedBox('pdf_label_date', '09/04/2026'),
            ],
          ),
          const SizedBox(height: 8),
          _directText(
              'سـنـد قـبـض مـالـي (مـعـايـنـة)', 13, const Color(0xFF0F2741),
              bold: true, align: TextAlign.center),
          if (isTripartite) ...[
            const SizedBox(height: 1),
            _selectableText('pdf_mediator_name', 8.0, const Color(0xFF64748B),
                align: TextAlign.center),
          ],
        ],
      ),
    );
  }

  Widget _buildExactEntrySection(
      {bool isTripartite = false, String sectionType = 'debit'}) {
    final isDebit = sectionType == 'debit';
    final sectionLabel = isTripartite
        ? (isDebit
            ? 'بيانات القيد (المدين) - من حساب العميل المرسل:'
            : 'بيانات القيد (الدائن) - إلى حساب العميل المستلم:')
        : 'pdf_label_from';

    final name = isTripartite
        ? (isDebit ? 'أحمد كمال الناصر' : 'خالد وليد العامري')
        : 'أحمد كمال الناصر';

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCBD5E1)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        if (isTripartite)
                          _directText(sectionLabel, 10, const Color(0xFF0F2741),
                              bold: true)
                        else
                          _selectableText(
                              'pdf_label_from', 10, const Color(0xFF0F2741),
                              bold: true),
                        const SizedBox(width: 5),
                        Text(name,
                            style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF047857),
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    _labeledLine(
                        'pdf_label_description',
                        isTripartite
                            ? (isDebit
                                ? 'إشعار بالخصم من الرصيد كتحويل مرسل'
                                : 'إشعار بالإضافة إلى الرصيد كتحويل مستلم')
                            : 'سداد دفعة من الفاتورة الآجلة المستحقة رقم 452'),
                  ],
                ),
              ),
            ),
            Container(
              width: 90,
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: Color(0xFFCBD5E1))),
              ),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: const Color(0xFF0F2741), width: 1.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _directText('#1,500.00\$#', 8, const Color(0xFF0F2741),
                      bold: true, dir: TextDirection.ltr),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExactSignatures({bool isTripartite = false}) {
    if (isTripartite) {
      return Row(
        children: [
          Expanded(child: _sigBoxMock('(توقيع العميل الأول)', true)),
          const SizedBox(width: 8),
          Expanded(child: _sigBoxMock('(توقيع العميل الثاني)', true)),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _sigBoxMock('(توقيع العميل المرسل)', true),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _directText('حالة التوقيع', 7, const Color(0xFF64748B)),
                const SizedBox(height: 3),
                _directText('مقبول وموقّع', 8, const Color(0xFF047857),
                    bold: true, align: TextAlign.center),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExactFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFCBD5E1))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _directText('تم الإنشاء:  09:30 AM  09/04/2026', 7.5,
                    const Color(0xFF64748B)),
                const SizedBox(height: 2),
                _selectableText(
                    'pdf_footer_text', 7.5, const Color(0xFF64748B)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.qr_code_2_rounded,
              size: 56, color: Color(0xFF0F2741)),
        ],
      ),
    );
  }

  // ── HELPERS ──────────────────────────────────────────────────────────────

  Widget _selectableText(String key, double size, Color color,
      {bool bold = false, TextAlign? align}) {
    final isSelected = _selectedKey == key;
    return InkWell(
      onTap: () => _selectField(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.amber.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
              color: isSelected ? Colors.amber : Colors.transparent, width: 1),
        ),
        child: Text(
          _config[key]!,
          style: GoogleFonts.cairo(
            fontSize: size,
            color: color,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            height: 1.35,
          ),
          textAlign: align,
        ),
      ),
    );
  }

  Widget _directText(String text, double size, Color color,
      {bool bold = false, TextAlign? align, TextDirection? dir}) {
    return Text(
      text,
      textDirection: dir,
      textAlign: align,
      style: GoogleFonts.cairo(
        fontSize: size,
        color: color,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        height: 1.35,
      ),
    );
  }

  Widget _borderedBox(String key, String value) {
    final isSelected = _selectedKey == key;
    return InkWell(
      onTap: () => _selectField(key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(
              color: isSelected ? Colors.amber : const Color(0xFF0F2741)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _directText(_config[key]!, 9, const Color(0xFF0F2741), bold: true),
            const SizedBox(width: 4),
            Text(value,
                style: GoogleFonts.cairo(
                    fontSize: 10, color: const Color(0xFF0F2741))),
          ],
        ),
      ),
    );
  }

  Widget _labeledLine(String key, String value) {
    return Row(
      children: [
        _selectableText(key, 9, const Color(0xFF0F2741), bold: true),
        const SizedBox(width: 4),
        Expanded(
            child: Text(value,
                style: GoogleFonts.cairo(
                    fontSize: 9, color: const Color(0xFF64748B)))),
      ],
    );
  }

  Widget _sigBoxMock(String label, bool hasSig) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (hasSig)
            Expanded(
              child: Center(
                child: _directText('✓ موقّع رقمياً', 9, const Color(0xFF047857),
                    bold: true),
              ),
            ),
          Container(height: 0.5, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 3),
          _directText(label, 8, const Color(0xFF64748B),
              align: TextAlign.center),
        ],
      ),
    );
  }
}
