import 'package:qayd/application/vouchers/dtos/advanced_filter_input.dart';

class ListVouchersInput {
  const ListVouchersInput({
    this.searchQuery,
    this.advancedFilter,
    this.limit,
    this.offset,
  });

  /// When null or blank after trim, listing uses [getAll] with filter only.
  final String? searchQuery;

  final AdvancedFilterInput? advancedFilter;
  final int? limit;
  final int? offset;
}
