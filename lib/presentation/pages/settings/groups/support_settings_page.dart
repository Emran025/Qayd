import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/entities/app_document.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
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
      final pi = await PackageInfo.fromPlatform();
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
      builder: (context) =>
          _TicketSubmissionDialog(typeTitle: typeTitle, typeCode: typeCode),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QaydAppBar(title: AppStringsAr.settingsGroupSupport),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
        children: [
          ListTile(
            leading: Icon(
              Icons.help_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(AppStringsAr.settingsFaqs),
            onTap: () => _showDocument(AppStringsAr.settingsFaqs, 'faq'),
          ),
          ListTile(
            leading: Icon(
              Icons.headset_mic_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(AppStringsAr.settingsContactSupport),
            onTap: () => _showSubmitTicket('تواصل مع الدعم الفني', 'other'),
          ),
          ListTile(
            leading: Icon(
              Icons.bug_report_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(AppStringsAr.settingsReportIssue),
            onTap: () => _showSubmitTicket('الإبلاغ عن مشكلة', 'bug'),
          ),
          ListTile(
            leading: Icon(
              Icons.new_releases_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('طلب ميزة جديدة'),
            onTap: () => _showSubmitTicket('طلب ميزة جديدة', 'feature_request'),
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.privacy_tip_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(AppStringsAr.settingsPrivacyPolicy),
            onTap: () => _showDocument(
              AppStringsAr.settingsPrivacyPolicy,
              'privacy_policy',
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.description_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(AppStringsAr.settingsTermsOfUse),
            onTap: () =>
                _showDocument(AppStringsAr.settingsTermsOfUse, 'terms_of_use'),
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
                _fallbackContent = doc.content.isNotEmpty
                    ? doc.content
                    : 'لا يوجد محتوى متوفر حالياً.';
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
    final scheme = Theme.of(context).colorScheme;
    final custom = Theme.of(context).extension<QaydCustomColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: custom.subtleBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.2),
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
                  style: textTheme.titleLarge?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: scheme.onSurfaceVariant),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: custom.subtleBorder.withValues(alpha: 0.5)),
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(color: scheme.primary),
                  )
                : _clauses.isNotEmpty
                    ? ListView.separated(
                        padding: const EdgeInsets.all(SpacingTokens.lg),
                        itemCount: _clauses.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: SpacingTokens.lg),
                        itemBuilder: (context, index) {
                          final clause = _clauses[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    custom.subtleBorder.withValues(alpha: 0.3),
                              ),
                            ),
                            padding: const EdgeInsets.all(SpacingTokens.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  clause.title,
                                  style: textTheme.titleMedium?.copyWith(
                                    color: scheme.tertiary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: SpacingTokens.sm),
                                ...clause.details.map(
                                  (detail) => Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '•',
                                          style: TextStyle(
                                            color: scheme.primary,
                                            fontSize: 16,
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            detail,
                                            style:
                                                textTheme.bodyMedium?.copyWith(
                                              color: scheme.onSurface,
                                              height: 1.6,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(SpacingTokens.lg),
                        child: Text(
                          _fallbackContent,
                          style: textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface,
                            height: 1.6,
                          ),
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

  const _TicketSubmissionDialog({
    required this.typeTitle,
    required this.typeCode,
  });

  @override
  State<_TicketSubmissionDialog> createState() =>
      _TicketSubmissionDialogState();
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
        const SnackBar(
          content: Text('تم إرسال الطلب بنجاح. سنراجع طلبك في أقرب وقت.'),
          backgroundColor: Colors.green,
        ),
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
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ),
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
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('إرسال'),
        ),
      ],
    );
  }
}
