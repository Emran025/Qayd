import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:qayd/application/accounts/dtos/account_statement_line_dto.dart';
import 'package:qayd/application/accounts/dtos/account_summary_dto.dart';
import 'package:qayd/application/vouchers/dtos/voucher_summary_dto.dart';
import 'package:qayd/data/export/qayd_excel_workbook.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';

String _moneyMinor(int minorUnits, {int digits = 2, String? symbol}) {
  num divisor = 1;
  for (var i = 0; i < digits; i++) {
    divisor *= 10;
  }
  final v = minorUnits / divisor;
  final formatted = NumberFormat('#,##0.${'0' * digits}', 'ar').format(v);
  return symbol != null ? '$formatted $symbol' : formatted;
}

String _formatDateIso(String iso) {
  try {
    final d = DateTime.parse(iso);
    return DateFormat.yMMMd('ar').format(d);
  } catch (_) {
    return iso;
  }
}

String _voucherTypeAr(String code) {
  switch (code) {
    case 'receipt':
      return AppStringsAr.voucherTypeReceipt;
    case 'payment':
      return AppStringsAr.voucherTypePayment;
    default:
      return code;
  }
}

String _voucherStateAr(String code) {
  switch (code) {
    case 'draft':
      return AppStringsAr.voucherStateDraft;
    case 'confirmed':
      return AppStringsAr.voucherStateConfirmed;
    case 'settled':
      return AppStringsAr.voucherStateSettled;
    default:
      return code;
  }
}

String _natureAr(String code) {
  switch (code) {
    case 'debit':
      return AppStringsAr.natureDebitShort;
    case 'credit':
      return AppStringsAr.natureCreditShort;
    default:
      return code;
  }
}

String _agreementStatusAr(String code) {
  switch (code) {
    case 'underRequest':
      return AppStringsAr.agreementUnderRequest;
    case 'accepted':
      return AppStringsAr.agreementAccepted;
    case 'rejected':
      return AppStringsAr.agreementRejected;
    case 'unverified':
      return AppStringsAr.agreementUnverified;
    default:
      return code;
  }
}

Uint8List buildVouchersExcelBytes(List<VoucherSummaryDto> vouchers) {
  final headers = [
    'التاريخ',
    'النوع',
    'الحالة',
    'اتفاق التوقيع',
    'المبلغ',
    'الطرف المقابل',
    'الحساب المتأثر',
    'المعرّف',
  ];
  final rows = <List<Object?>>[];
  for (final v in vouchers) {
    rows.add([
      _formatDateIso(v.dateIso),
      _voucherTypeAr(v.typeCode),
      _voucherStateAr(v.stateCode),
      _agreementStatusAr(v.agreementStatusCode),
      _moneyMinor(
        v.amountMinorUnits,
        digits: v.currencyDigits,
        symbol: v.currencySymbol,
      ),
      v.counterpartyName,
      v.affectedName,
      v.id,
    ]);
  }
  return QaydExcelWorkbook.buildVouchers(headers: headers, rows: rows);
}

Uint8List buildAccountsExcelBytes(List<AccountSummaryDto> accounts) {
  final headers = [
    'اسم الحساب',
    'الطبيعة',
    'الرصيد',
    'نشط',
    'جذر',
    'المعرّف',
  ];
  final rows = <List<Object?>>[];
  for (final a in accounts) {
    rows.add([
      a.name,
      _natureAr(a.natureCode),
      a.balancesMinorUnits.entries
          .map((e) => _moneyMinor(e.value, symbol: e.key))
          .join(', '),
      a.isActive ? AppStringsAr.statusActive : AppStringsAr.statusInactive,
      a.isRoot ? AppStringsAr.accountTypeRoot : AppStringsAr.accountTypeChild,
      a.id,
    ]);
  }
  return QaydExcelWorkbook.buildAccounts(headers: headers, rows: rows);
}

Uint8List buildAccountStatementExcelBytes({
  required String accountName,
  required List<AccountStatementLineDto> lines,
}) {
  final headers = [
    'التاريخ',
    'البيان',
    'مدين',
    'دائن',
    'الرصيد',
    'سند',
  ];
  final rows = <List<Object?>>[];
  for (final line in lines) {
    rows.add([
      _formatDateIso(line.dateIso),
      line.description,
      _moneyMinor(line.debitMinorUnits),
      _moneyMinor(line.creditMinorUnits),
      _moneyMinor(line.balanceMinorUnits),
      line.voucherId,
    ]);
  }
  return QaydExcelWorkbook.buildAccountStatement(
    accountName: accountName,
    headers: headers,
    rows: rows,
  );
}

Uint8List buildCombinedExportExcelBytes({
  required List<VoucherSummaryDto> vouchers,
  required List<AccountSummaryDto> accounts,
}) {
  final vHeaders = [
    'التاريخ',
    'النوع',
    'الحالة',
    'اتفاق التوقيع',
    'المبلغ',
    'الطرف المقابل',
    'الحساب المتأثر',
  ];
  final vRows = <List<Object?>>[];
  for (final v in vouchers) {
    vRows.add([
      _formatDateIso(v.dateIso),
      _voucherTypeAr(v.typeCode),
      _voucherStateAr(v.stateCode),
      _agreementStatusAr(v.agreementStatusCode),
      _moneyMinor(
        v.amountMinorUnits,
        digits: v.currencyDigits,
        symbol: v.currencySymbol,
      ),
      v.counterpartyName,
      v.affectedName,
    ]);
  }
  final aHeaders = [
    'اسم الحساب',
    'الطبيعة',
    'الرصيد',
    'نشط',
  ];
  final aRows = <List<Object?>>[];
  for (final a in accounts) {
    aRows.add([
      a.name,
      _natureAr(a.natureCode),
      a.balancesMinorUnits.entries
          .map((e) => _moneyMinor(e.value, symbol: e.key))
          .join(', '),
      a.isActive ? AppStringsAr.statusActive : AppStringsAr.statusInactive,
    ]);
  }
  return QaydExcelWorkbook.buildCombined(
    voucherHeaders: vHeaders,
    voucherRows: vRows,
    accountHeaders: aHeaders,
    accountRows: aRows,
  );
}
