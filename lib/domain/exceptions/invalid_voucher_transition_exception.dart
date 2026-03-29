import 'package:qayd/domain/value_objects/voucher_state.dart';

/// Thrown when a [Voucher] lifecycle transition violates voucher rules.
class InvalidVoucherTransitionException implements Exception {
  InvalidVoucherTransitionException({
    required this.messageAr,
    required this.from,
    required this.to,
  });

  final String messageAr;
  final VoucherState from;
  final VoucherState to;

  @override
  String toString() =>
      'InvalidVoucherTransitionException($from -> $to): $messageAr';
}
