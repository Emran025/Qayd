import 'package:flutter_test/flutter_test.dart';
import 'package:qayd/application/suggestions/suggestion_pattern_extractor.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';

void main() {
  group('SuggestionPatternExtractor', () {
    test('extracts amount and receipt keyword (Arabic)', () {
      const text = 'استلمت حوالة واردة مبلغ 250 ﷼';
      final ex = SuggestionPatternExtractor.extract(text);
      expect(ex.direction, SuggestionDirection.receipt);
      expect(ex.amountMinorUnits, 25000);
    });

    test('extracts payment keyword', () {
      const text = 'تم سحب مبلغ 200 من الحساب';
      final ex = SuggestionPatternExtractor.extract(text);
      expect(ex.direction, SuggestionDirection.payment);
      expect(ex.amountMinorUnits, 20000);
    });

    test('maps direction to voucher type', () {
      expect(
        SuggestionPatternExtractor.toVoucherType(SuggestionDirection.receipt),
        VoucherType.receipt,
      );
      expect(
        SuggestionPatternExtractor.toVoucherType(SuggestionDirection.payment),
        VoucherType.payment,
      );
    });
  });
}
