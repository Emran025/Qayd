import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/pos_invoice.dart';
import 'package:qayd/domain/repositories/pos_invoice_read_repository.dart';

final class ListPosInvoicesUseCase {
  const ListPosInvoicesUseCase({required PosInvoiceReadRepository repository})
      : _repository = repository;

  final PosInvoiceReadRepository _repository;

  Future<Result<List<PosInvoice>>> call({
    DateTime? from,
    DateTime? to,
    PosInvoiceType? type,
    int? limit,
  }) =>
      _repository.list(from: from, to: to, type: type, limit: limit);
}
