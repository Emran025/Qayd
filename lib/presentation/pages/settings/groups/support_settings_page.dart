import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/entities/app_document.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

class SupportSettingsPage extends StatefulWidget {
  const SupportSettingsPage({super.key});

  @override
  State<SupportSettingsPage> createState() => _SupportSettingsPageState();
}

class _SupportSettingsPageState extends State<SupportSettingsPage> {
  String _versionInfo = 'جاري التحميل...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
    // Pre-fetch/refresh documents softly
    InjectionContainer.appConfigRepository.getDocuments(forceRefresh: true);
  }

  Future<void> _loadVersion() async {
    try {
      final  pi = await PackageInfo.fromPlatform();
      setState(() {
        _versionInfo = 'الإصدار ${pi.version}';
      });
    } catch (_) {
      setState(() {
        _versionInfo = 'غير متوفر';
      });
    }
  }

  Future<void> _showDocument(String title, String docType) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DocumentViewer(title: title, docType: docType),
    );
  }

  Future<void> _showSubmitTicket(String typeTitle, String typeCode) async {
    showDialog(
      context: context,
      builder: (context) => _TicketSubmissionDialog(typeTitle: typeTitle, typeCode: typeCode),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStringsAr.settingsGroupSupport),
      ),

      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
        children: [
          ListTile(
            leading: Icon(Icons.help_outline, color: Theme.of(context).colorScheme.primary),
            title: Text(AppStringsAr.settingsFaqs),
            onTap: () => _showDocument(AppStringsAr.settingsFaqs, 'faq'),
          ),
          ListTile(
            leading: Icon(Icons.headset_mic_outlined, color: Theme.of(context).colorScheme.primary),
            title: Text(AppStringsAr.settingsContactSupport),
            onTap: () => _showSubmitTicket('تواصل مع الدعم الفني', 'other'),
          ),
          ListTile(
            leading: Icon(Icons.bug_report_outlined, color: Theme.of(context).colorScheme.primary),
            title: Text(AppStringsAr.settingsReportIssue),
            onTap: () => _showSubmitTicket('الإبلاغ عن مشكلة', 'bug'),
          ),
          ListTile(
            leading: Icon(Icons.new_releases_outlined, color: Theme.of(context).colorScheme.primary),
            title: const Text('طلب ميزة جديدة'),
            onTap: () => _showSubmitTicket('طلب ميزة جديدة', 'feature_request'),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.privacy_tip_outlined, color: Theme.of(context).colorScheme.primary),
            title: Text(AppStringsAr.settingsPrivacyPolicy),
            onTap: () => _showDocument(AppStringsAr.settingsPrivacyPolicy, 'privacy_policy'),
          ),
          ListTile(
            leading: Icon(Icons.description_outlined, color: Theme.of(context).colorScheme.primary),
            title: Text(AppStringsAr.settingsTermsOfUse),
            onTap: () => _showDocument(AppStringsAr.settingsTermsOfUse, 'terms_of_use'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(AppStringsAr.settingsVersionInfo),
            subtitle: Text(_versionInfo),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _DocumentViewer extends StatefulWidget {
  final String title;
  final String docType;

  const _DocumentViewer({required this.title, required this.docType});

  @override
  State<_DocumentViewer> createState() => _DocumentViewerState();
}

class _DocumentViewerState extends State<_DocumentViewer> {
  bool _loading = true;
  String _fallbackContent = '';
  List<DocumentClause> _clauses = [];

  @override
  void initState() {
    super.initState();
    _loadDocs();
  }

  Future<void> _loadDocs() async {
    final result = await InjectionContainer.appConfigRepository.getDocuments();
    result.fold(
      (failure) {
        if (mounted) {
          setState(() {
            _loading = false;
            _fallbackContent = 'تعذر تحميل المحتوى.';
          });
        }
      },
      (docs) {
        if (mounted) {
          setState(() {
            _loading = false;
            final doc = docs[widget.docType];
            if (doc != null) {
              if (doc.clauses.isNotEmpty) {
                _clauses = doc.clauses;
              } else {
                _fallbackContent = doc.content.isNotEmpty ? doc.content : 'لا يوجد محتوى متوفر حالياً.';
              }
            } else {
              _fallbackContent = 'لا يوجد محتوى متوفر حالياً.';
            }
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF334155),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: ColorTokens.slate400),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: ColorTokens.slate800),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: ColorTokens.goldAccent))
                : _clauses.isNotEmpty
                    ? ListView.separated(
                        padding: const EdgeInsets.all(SpacingTokens.lg),
                        itemCount: _clauses.length,
                        separatorBuilder: (context, index) => const SizedBox(height: SpacingTokens.lg),
                        itemBuilder: (context, index) {
                          final clause = _clauses[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B), // slate800
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(SpacingTokens.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  clause.title,
                                  style: const TextStyle(
                                    color: ColorTokens.goldAccent,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: SpacingTokens.sm),
                                ...clause.details.map((detail) => Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '•',
                                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16, height: 1.2),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              detail,
                                              style: const TextStyle(
                                                color: Color(0xFFCBD5E1),
                                                fontSize: 14,
                                                height: 1.6,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                              ],
                            ),
                          );
                        },
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(SpacingTokens.lg),
                        child: Text(
                          _fallbackContent,
                          style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14, height: 1.6),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _TicketSubmissionDialog extends StatefulWidget {
  final String typeTitle;
  final String typeCode;

  const _TicketSubmissionDialog({required this.typeTitle, required this.typeCode});

  @override
  State<_TicketSubmissionDialog> createState() => _TicketSubmissionDialogState();
}

class _TicketSubmissionDialogState extends State<_TicketSubmissionDialog> {
  final _msgCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final msg = _msgCtrl.text.trim();
    if (msg.isEmpty) return;

    setState(() => _loading = true);

    await InjectionContainer.appConfigRepository.submitSupportTicket(
      type: widget.typeCode,
      message: msg,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال الطلب بنجاح. سنراجع طلبك في أقرب وقت.'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.typeTitle),
      content: TextField(
        controller: _msgCtrl,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: 'اكتب تفاصيل الرسالة هنا...',
          border: const OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
          child: _loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('إرسال'),
        ),
      ],
    );
  }
}
