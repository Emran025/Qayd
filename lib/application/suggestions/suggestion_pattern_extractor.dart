import 'package:qayd/domain/value_objects/voucher_type.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


/// Offline regex extraction from SMS / notification bodies (Arabic + English).
enum SuggestionDirection {
  receipt,
  payment,
}

/// Extracted fields; any may be null if not found.
final class SuggestionExtract {
  const SuggestionExtract({
    this.amountMinorUnits,
    this.date,
    this.direction,
    this.signatureHex,
    this.publicKeyHex,
  });

  final int? amountMinorUnits;
  final DateTime? date;
  final SuggestionDirection? direction;
  final String? signatureHex;
  final String? publicKeyHex;
}

/// Deterministic pattern matching — no network / ML.
abstract final class SuggestionPatternExtractor {
  static final RegExp _isoDate = RegExp(
    r'\b(20\d{2})-(\d{2})-(\d{2})\b',
  );
  static final RegExp _dmyDate = RegExp(
    r'\b(\d{1,2})[/.-](\d{1,2})[/.-](\d{2,4})\b',
  );
  static final RegExp _number = RegExp(
    r'\d{1,3}(?:[,\u066C\s]\d{3})*(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?',
  );
  static final RegExp _hexSignature = RegExp(
    AppStrings.fingerprintsignaturesigsignaturessafaf0932128,
    caseSensitive: false,
  );
  static final RegExp _hexPublicKey = RegExp(
    AppStrings.keypkpublickeyssafaf0932128,
    caseSensitive: false,
  );

  static SuggestionExtract extract(String raw, {DateTime? referenceNow}) {
    final now = referenceNow ?? DateTime.now();
    final text = _normalizeDigits(raw.trim());
    if (text.isEmpty) {
      return const SuggestionExtract();
    }
    return SuggestionExtract(
      amountMinorUnits: _extractAmountMinor(text),
      date: _extractDate(text, now),
      direction: _extractDirection(raw),
      signatureHex: _extractHex(raw, _hexSignature),
      publicKeyHex: _extractHex(raw, _hexPublicKey),
    );
  }

  static String? _extractHex(String text, RegExp pattern) {
    final match = pattern.firstMatch(text);
    return match?.group(1);
  }

  static String _normalizeDigits(String s) {
    final ar = AppStrings.s0123456789;
    const en = '0123456789';
    var o = s;
    for (var i = 0; i < ar.length; i++) {
      o = o.replaceAll(ar[i], en[i]);
    }
    return o;
  }

  static int? _extractAmountMinor(String text) {
    final matches = _number.allMatches(text);
    int? best;
    for (final m in matches) {
      final seg = m.group(0);
      if (seg == null) continue;
      final minor = _segmentToMinor(seg);
      if (minor != null && minor > 0) {
        if (best == null || minor > best) {
          best = minor;
        }
      }
    }
    if (best != null && best <= 999999999999) {
      return best;
    }
    return null;
  }

  static int? _segmentToMinor(String segment) {
    var t = segment.replaceAll(RegExp(r'[\s\u066C]'), '');
    t = t.replaceAll(',', '.');
    if (t.split('.').length > 2) {
      t = t.replaceAll('.', '');
    }
    final v = double.tryParse(t);
    if (v == null || v <= 0) return null;
    return (v * 100).round();
  }

  static DateTime? _extractDate(String text, DateTime now) {
    final iso = _isoDate.firstMatch(text);
    if (iso != null) {
      final y = int.tryParse(iso.group(1)!);
      final mo = int.tryParse(iso.group(2)!);
      final d = int.tryParse(iso.group(3)!);
      if (y != null && mo != null && d != null) {
        return DateTime(y, mo, d);
      }
    }
    final dm = _dmyDate.firstMatch(text);
    if (dm != null) {
      final a = int.tryParse(dm.group(1)!);
      final b = int.tryParse(dm.group(2)!);
      var y = int.tryParse(dm.group(3)!);
      if (a != null && b != null && y != null) {
        if (y < 100) y += 2000;
        if (a > 12) {
          return DateTime(y, b, a);
        }
        return DateTime(y, a, b);
      }
    }
    return null;
  }

  static SuggestionDirection? _extractDirection(String raw) {
    final t = raw.toLowerCase();
    final ar = raw;

    var receiptScore = 0;
    var paymentScore = 0;

    final receiptAr = [
      AppStrings.iReceived,
      AppStrings.deposited,
      AppStrings.iDeposited,
      AppStrings.incomingTransfer1,
      AppStrings.incomingTransfer,
      AppStrings.incoming,
      AppStrings.deposit,
      AppStrings.deposit1,
    ];
    final paymentAr = [
      AppStrings.sent1,
      AppStrings.sent,
      AppStrings.toWithdraw,
      AppStrings.outgoingTransfer2,
      AppStrings.outgoingTransfer,
      AppStrings.issued,
      AppStrings.outgoingTransfer1,
    ];
    const receiptEn = ['received', 'incoming', 'credit', 'deposit'];
    const paymentEn = ['sent', 'withdraw', 'outgoing', 'debit', 'transfer out'];

    for (final k in receiptAr) {
      if (ar.contains(k)) receiptScore += 2;
    }
    for (final k in paymentAr) {
      if (ar.contains(k)) paymentScore += 2;
    }
    for (final k in receiptEn) {
      if (t.contains(k)) receiptScore += 1;
    }
    for (final k in paymentEn) {
      if (t.contains(k)) paymentScore += 1;
    }

    if (receiptScore == 0 && paymentScore == 0) return null;
    if (receiptScore > paymentScore) return SuggestionDirection.receipt;
    if (paymentScore > receiptScore) return SuggestionDirection.payment;
    return null;
  }

  static VoucherType? toVoucherType(SuggestionDirection? d) {
    if (d == null) return null;
    return d == SuggestionDirection.receipt
        ? VoucherType.receipt
        : VoucherType.payment;
  }
}
