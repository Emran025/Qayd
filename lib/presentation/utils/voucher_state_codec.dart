import 'package:qayd/domain/value_objects/voucher_state.dart';

VoucherState voucherStateFromCode(String code) {
  for (final v in VoucherState.values) {
    if (v.name == code) {
      return v;
    }
  }
  return VoucherState.draft;
}
