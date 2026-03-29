import 'package:flutter/material.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';

class CurrencyPickerSheet extends StatefulWidget {
  const CurrencyPickerSheet({super.key, this.selectedCode});

  final String? selectedCode;

  static Future<CurrencyCode?> show(BuildContext context, {String? selectedCode}) {
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
    _currenciesFuture = InjectionContainer.listCurrenciesUseCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B), // Navy Lighter
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'اختر العملة',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<Result<List<CurrencyCode>>>(
              future: _currenciesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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
                        color: isSelected ? const Color(0xFF38BDF8).withOpacity(0.1) : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected ? Border.all(color: const Color(0xFF38BDF8)) : null,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          child: Text(c.symbol, style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(
                          c.nameAr,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          c.code,
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.white.withOpacity(0.5)),
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
