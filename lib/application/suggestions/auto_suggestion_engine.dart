import 'package:qayd/application/suggestions/scored_suggestion_dto.dart';
import 'package:qayd/application/suggestions/suggestion_pattern_extractor.dart';
import 'package:qayd/domain/entities/notification_message.dart';

/// Ranks messages by recency + extracted-field completeness.
abstract final class AutoSuggestionEngine {
  static List<ScoredSuggestionDto> build(
    List<NotificationMessage> messages,
    DateTime now,
  ) {
    final out = <ScoredSuggestionDto>[];
    for (final m in messages) {
      final ex = SuggestionPatternExtractor.extract(
        m.bodyText,
        referenceNow: now,
      );
      // Only suggest if we successfully extracted a matching amount
      if (ex.amountMinorUnits == null) continue;
      final completeness =
          3.0 + (ex.date != null ? 2.0 : 0) + (ex.direction != null ? 2.0 : 0);
      final ageDays = now.difference(m.createdAt).inDays.clamp(0, 730);
      final recency = 12.0 / (1 + ageDays * 0.15);
      final score = completeness * 6.0 + recency;
      out.add(
        ScoredSuggestionDto(
          messageId: m.id,
          rawBody: m.bodyText,
          createdAt: m.createdAt,
          score: score,
          amountMinorUnits: ex.amountMinorUnits,
          date: ex.date,
          type: SuggestionPatternExtractor.toVoucherType(ex.direction),
          signatureHex: ex.signatureHex,
          publicKeyHex: ex.publicKeyHex,
        ),
      );
    }
    out.sort((a, b) => b.score.compareTo(a.score));
    return out;
  }
}
