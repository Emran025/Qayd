/// Role of a voucher within a tripartite intermediary transfer group.
///
/// - [intermediaryReceipt]: The receipt leg — money flows from Source (A) to Mediator (C).
/// - [intermediaryPayment]: The payment leg — money flows from Mediator (C) to Destination (B).
enum TripartiteRole {
  intermediaryReceipt,
  intermediaryPayment;

  bool get isReceipt => this == TripartiteRole.intermediaryReceipt;
  bool get isPayment => this == TripartiteRole.intermediaryPayment;

  /// DB column value: snake_case string.
  String get columnValue => switch (this) {
        TripartiteRole.intermediaryReceipt => 'intermediary_receipt',
        TripartiteRole.intermediaryPayment => 'intermediary_payment',
      };

  /// Parses from DB column value; returns null for unrecognised strings.
  static TripartiteRole? fromColumnValue(String? raw) => switch (raw) {
        'intermediary_receipt' => TripartiteRole.intermediaryReceipt,
        'intermediary_payment' => TripartiteRole.intermediaryPayment,
        _ => null,
      };
}
