import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/entities/accrual_component.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/pages/accruals/accrual_create_page.dart';
import 'package:qayd/presentation/pages/cost_centers/cost_center_dashboard_widgets.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/widgets/qayd_scaffold.dart';

class AccrualListPage extends StatefulWidget {
  const AccrualListPage({super.key});

  @override
  State<AccrualListPage> createState() => _AccrualListPageState();
}

class _AccrualListPageState extends State<AccrualListPage> {
  bool _loading = true;
  List<AccrualComponent> _accruals = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await InjectionContainer.listAccrualsUseCase();
    res.fold(
      (_) => setState(() => _loading = false),
      (data) => setState(() {
        _accruals = data;
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalMonthly = _calculateMonthlyTotal();

    return QaydScaffold(
      appBar: const QaydAppBar(
        title: 'الالتزامات و الاستحقاقات',
        leading: BackButton(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => AccrualCreatePage(onCreated: _load)),
        ),
        label: const Text('إضافة التزام'),
        icon: const Icon(Icons.add_task_rounded),
        backgroundColor: ColorTokens.warningAmber,
        foregroundColor: ColorTokens.navy950,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // ── Hero Summary ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(SpacingTokens.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ColorTokens.navy900,
                          ColorTokens.navy800,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        const QaydText(
                          'إجمالي الالتزامات الشهرية المقدرة',
                          slot: QaydTextStyleSlot.labelMedium,
                          color: Colors.white70,
                        ),
                        const SizedBox(height: SpacingTokens.xs),
                        Text(
                          '${NumberFormat.decimalPattern().format(totalMonthly)} SAR',
                          style: const TextStyle(
                            color: ColorTokens.warningAmber,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: SpacingTokens.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _SummaryItem(
                              label: 'نشط',
                              value: _accruals
                                  .where((e) => e.isActive)
                                  .length
                                  .toString(),
                              icon: Icons.check_circle_outline_rounded,
                              color: ColorTokens.emerald400,
                            ),
                            _SummaryItem(
                              label: 'مستحق قريباً',
                              value: _countDueSoon().toString(),
                              icon: Icons.access_time_rounded,
                              color: ColorTokens.warningAmber,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── List ───────────────────────────────────────────────────
                if (_accruals.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: QaydText('لا توجد التزامات مجدولة بعد.'),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(SpacingTokens.md),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = _accruals[index];
                          return _AccrualCard(
                            item: item,
                            onProcessed: _load,
                          );
                        },
                        childCount: _accruals.length,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  double _calculateMonthlyTotal() {
    double total = 0;
    for (final a in _accruals) {
      if (!a.isActive) continue;
      switch (a.frequency) {
        case AccrualFrequency.daily:
          total += a.amount * 30;
        case AccrualFrequency.weekly:
          total += a.amount * 4;
        case AccrualFrequency.monthly:
          total += a.amount;
        case AccrualFrequency.quarterly:
          total += a.amount / 3;
        case AccrualFrequency.semiAnnually:
          total += a.amount / 6;
        case AccrualFrequency.yearly:
          total += a.amount / 12;
        case AccrualFrequency.once:
          total += 0; // Not a recurring monthly cost in this context
      }
    }
    return total;
  }

  int _countDueSoon() {
    final now = DateTime.now();
    final soon = now.add(const Duration(days: 7));
    return _accruals
        .where((e) => e.isActive && e.nextDueDate.isBefore(soon))
        .length;
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 10),
        ),
      ],
    );
  }
}

class _AccrualCard extends StatelessWidget {
  const _AccrualCard({required this.item, required this.onProcessed});
  final AccrualComponent item;
  final VoidCallback onProcessed;

  Future<void> _onPay(BuildContext context) async {
    final scaffold = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('تأكيد تنفيذ الالتزام'),
              content: Text(
                  'هل تود تسجيل مبلغ ${item.amount} ${item.currencyCode} كعملية دفع حقيقية؟'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('إلغاء')),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('نعم، تم الدفع')),
              ],
            ));

    if (confirm != true) return;

    final res = await InjectionContainer.processAccrualUseCase(item.id);
    res.fold(
      (f) => scaffold.showSnackBar(SnackBar(content: Text(f.messageAr))),
      (_) {
        scaffold.showSnackBar(const SnackBar(
            content: Text('تم تنفيذ الاستحقاق وتسجيل العملية بنجاح.')));
        onProcessed();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDueSoon =
        item.nextDueDate.isBefore(DateTime.now().add(const Duration(days: 3)));

    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.md),
      child: GlassCard(
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Indicator strip
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color:
                      isDueSoon ? ColorTokens.errorSoft : ColorTokens.debitBlue,
                  borderRadius: BorderRadius.circular(RadiusTokens.pill),
                ),
              ),
              const SizedBox(width: SpacingTokens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          '${item.amount} ${item.currencyCode}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: scheme.primary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.frequency.labelAr,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: SpacingTokens.sm),
                    Row(
                      children: [
                        Icon(
                          Icons.event_repeat_rounded,
                          size: 14,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'الاستحقاق القادم: ${DateFormat('yyyy-MM-dd').format(item.nextDueDate)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDueSoon
                                ? ColorTokens.errorSoft
                                : scheme.onSurfaceVariant,
                            fontWeight: isDueSoon ? FontWeight.bold : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: SpacingTokens.md),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: () => _onPay(context),
                    icon: const Icon(Icons.payments_rounded),
                    tooltip: 'تسجيل عملية دفع',
                    style: IconButton.styleFrom(
                      backgroundColor:
                          ColorTokens.emerald400.withValues(alpha: 0.1),
                      foregroundColor: ColorTokens.emerald400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
