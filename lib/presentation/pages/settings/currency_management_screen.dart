import 'package:flutter/material.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/inputs/qayd_numeric_field.dart';

class CurrencyManagementScreen extends StatefulWidget {
  const CurrencyManagementScreen({super.key});

  @override
  State<CurrencyManagementScreen> createState() =>
      _CurrencyManagementScreenState();
}

class _CurrencyManagementScreenState extends State<CurrencyManagementScreen> {
  late Future<Result<List<CurrencyCode>>> _currenciesFuture;
  late Future<Result<String>> _baseCurrencyFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _currenciesFuture = InjectionContainer.listCurrenciesUseCase();
      _baseCurrencyFuture = InjectionContainer.getBaseCurrencyUseCase();
    });
  }

  Future<void> _showAddCurrencyDialog() async {
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    final symbolController = TextEditingController();
    final digitsController = TextEditingController(text: '2');

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة عملة جديدة', textAlign: TextAlign.right),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'رمز العملة (مثال: USD)',
                ),
                textAlign: TextAlign.right,
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم العملة بالعربية',
                ),
                textAlign: TextAlign.right,
              ),
              TextField(
                controller: symbolController,
                decoration: const InputDecoration(
                  labelText: 'رمز العملة (مثال: \$)',
                ),
                textAlign: TextAlign.right,
              ),
              QaydNumericField(
                controller: digitsController,
                label: 'عدد الأرقام العشرية',
                maxLength: 1,
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.isEmpty || nameController.text.isEmpty) {
                return;
              }
              final currency = CurrencyCode(
                code: codeController.text.toUpperCase(),
                nameAr: nameController.text,
                symbol: symbolController.text,
                fractionalDigits: int.tryParse(digitsController.text) ?? 2,
                isActive: true,
              );
              final res = await InjectionContainer.addCurrencyUseCase(currency);
              if (res.isSuccess) {
                if (context.mounted) Navigator.pop(context);
                _refresh();
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: QaydAppBar(
        title: 'إدارة العملات',
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCurrencyDialog,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Object>>(
        future: Future.wait([_currenciesFuture, _baseCurrencyFuture]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final currenciesRes = snapshot.data![0] as Result<List<CurrencyCode>>;
          final baseRes = snapshot.data![1] as Result<String>;

          if (currenciesRes.isFailure) {
            return Center(child: Text(currenciesRes.failureOrNull!.messageAr));
          }

          final currencies = currenciesRes.valueOrNull!;
          final baseCode = baseRes.valueOrNull ?? 'SAR';

          return ListView.builder(
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
            itemCount: currencies.length,
            itemBuilder: (context, index) {
              final c = currencies[index];
              final isBase = c.code == baseCode;

              return Opacity(
                opacity: c.isActive ? 1.0 : 0.6,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: isBase
                        ? Border.all(color: scheme.primary, width: 1.5)
                        : null,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isBase
                            ? scheme.primary.withOpacity(0.1)
                            : scheme.onSurface.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        c.symbol,
                        style: TextStyle(
                          color: isBase ? scheme.primary : scheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    title: Text(
                      c.nameAr,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.bold,
                        decoration:
                            c.isActive ? null : TextDecoration.lineThrough,
                      ),
                    ),
                    subtitle: Text(
                      c.code,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isBase)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'الأساسية',
                              style: TextStyle(
                                color: scheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          IconButton(
                            icon: Icon(
                              c.isActive
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: c.isActive
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                            ),
                            onPressed: () async {
                              final res = await InjectionContainer
                                  .toggleCurrencyStatusUseCase(
                                c.code,
                                !c.isActive,
                              );
                              if (res.isSuccess) {
                                _refresh();
                              }
                            },
                          ),
                        if (!isBase && c.isActive)
                          IconButton(
                            icon: const Icon(Icons.star_border, size: 20),
                            onPressed: () async {
                              final res = await InjectionContainer
                                  .setBaseCurrencyUseCase(
                                c.code,
                              );
                              if (res.isSuccess) {
                                _refresh();
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
