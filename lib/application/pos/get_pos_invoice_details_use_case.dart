import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/pos_invoice_details.dart';
import 'package:qayd/domain/repositories/pos_invoice_read_repository.dart';

final class GetPosInvoiceDetailsUseCase {
  const GetPosInvoiceDetailsUseCase(
      {required PosInvoiceReadRepository repository})
      : _repository = repository;

  final PosInvoiceReadRepository _repository;

  Future<Result<PosInvoiceDetails?>> call(String invoiceId) =>
      _repository.getById(invoiceId);
}
