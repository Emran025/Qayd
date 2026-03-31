import 'package:flutter/material.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';

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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إدارة العملات',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
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
            padding: const EdgeInsets.all(16),
            itemCount: currencies.length,
            itemBuilder: (context, index) {
              final c = currencies[index];
              final isBase = c.code == baseCode;

              return Container(
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
                    ),
                  ),
                  subtitle: Text(
                    c.code,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  trailing: isBase
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'العملة الأساسية',
                            style: TextStyle(
                              color: scheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : TextButton(
                          onPressed: () async {
                            final res =
                                await InjectionContainer.setBaseCurrencyUseCase(
                                  c.code,
                                );
                            if (res.isSuccess) {
                              _refresh();
                            }
                          },
                          child: Text(
                            'تعيين كأساسية',
                            style: TextStyle(
                              color: scheme.primary,
                              fontSize: 12,
                            ),
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
