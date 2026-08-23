import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/pos_sale_posting.dart';

/// Persistence boundary for a complete, immutable POS sale posting.
abstract interface class PosSalePostingRepository {
  Future<Result<void>> saveAtomically(PosSalePosting posting);
}
