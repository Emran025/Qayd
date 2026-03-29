import 'package:qayd/domain/value_objects/voucher_type.dart';

/// One scored candidate for the voucher form (offline).
final class ScoredSuggestionDto {
  const ScoredSuggestionDto({
    required this.messageId,
    required this.rawBody,
    required this.createdAt,
    required this.score,
    this.amountMinorUnits,
    this.date,
    this.type,
  });

  final String messageId;
  final String rawBody;
  final DateTime createdAt;
  final double score;
  final int? amountMinorUnits;
  final DateTime? date;
  final VoucherType? type;
}
