import 'package:flutter/material.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


class CurrencyPickerSheet extends StatefulWidget {
  const CurrencyPickerSheet({super.key, this.selectedCode});

  final String? selectedCode;

  static Future<CurrencyCode?> show(BuildContext context,
      {String? selectedCode}) {
    return showModalBottomSheet<CurrencyCode>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CurrencyPickerSheet(selectedCode: selectedCode),
    );
  }

  @override
  State<CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<CurrencyPickerSheet> {
  late Future<Result<List<CurrencyCode>>> _currenciesFuture;

  @override
  void initState() {
    super.initState();
    _currenciesFuture =
        InjectionContainer.listCurrenciesUseCase(onlyActive: true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      padding:  EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.onSurfaceVariant.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 24),
          Text(
            AppStrings.selectCurrency,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<Result<List<CurrencyCode>>>(
              future: _currenciesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                final res = snapshot.data!;
                if (res.isFailure) {
                  return Center(child: Text(res.failureOrNull!.messageAr));
                }

                final list = res.valueOrNull!;
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final c = list[index];
                    final isSelected = c.code == widget.selectedCode;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: scheme.primary, width: 1.5)
                            : null,
                      ),
                      child: ListTile(
                        contentPadding:  EdgeInsets.symmetric(
                          horizontal: 12,
                          // vertical: 6,
                        ),
                        leading: Container(
                          padding:  EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? scheme.primary.withOpacity(0.1)
                                : scheme.onSurface.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            c.symbol,
                            style: TextStyle(
                              color: isSelected
                                  ? scheme.primary
                                  : scheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        title: Text(
                          c.nameAr,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          c.code,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        onTap: () => Navigator.pop(context, c),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
