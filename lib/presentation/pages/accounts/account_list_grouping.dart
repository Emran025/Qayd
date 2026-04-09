import 'package:qayd/application/accounts/dtos/account_summary_dto.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';

String accountSectionKey(AccountSummaryDto a) {
  if (a.standardClassificationKind != null) {
    return 'std:${a.standardClassificationKind}';
  }
  return 'custom:${a.customClassificationName ?? ''}';
}

String accountSectionTitleAr(AccountSummaryDto representative) {
  if (representative.standardClassificationKind != null) {
    return AppStringsAr.standardClassificationLabel(
      representative.standardClassificationKind!,
    );
  }
  return representative.customClassificationName ??
      AppStringsAr.classificationOther;
}

int _sectionRank(String key) {
  if (key.startsWith('std:')) {
    const order = [
      'assets',
      'liabilities',
      'equity',
      'income',
      'expenses',
    ];
    final name = key.substring(4);
    final i = order.indexOf(name);
    return i >= 0 ? i : 50;
  }
  return 100;
}

int compareSectionKeys(String a, String b) {
  final ra = _sectionRank(a);
  final rb = _sectionRank(b);
  if (ra != rb) {
    return ra.compareTo(rb);
  }
  return a.compareTo(b);
}

/// Ordered sections: each tuple is (section key, title, rows).
List<({String key, String title, List<AccountSummaryDto> rows})>
    buildAccountSections(
  List<AccountSummaryDto> filtered,
) {
  final map = <String, List<AccountSummaryDto>>{};
  for (final a in filtered) {
    final k = accountSectionKey(a);
    map.putIfAbsent(k, () => []).add(a);
  }
  for (final list in map.values) {
    list.sort((a, b) {
      if (a.isRoot != b.isRoot) {
        return a.isRoot ? -1 : 1;
      }
      return a.name.compareTo(b.name);
    });
  }
  final keys = map.keys.toList()..sort(compareSectionKeys);
  return [
    for (final k in keys)
      (
        key: k,
        title: accountSectionTitleAr(map[k]!.first),
        rows: map[k]!,
      ),
  ];
}
