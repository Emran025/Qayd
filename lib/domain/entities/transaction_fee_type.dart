enum TransactionFeeType {
  /// Standard tripartite transfer (A -> Me -> B) without using a box mediator.
  tripartite,

  /// Transfer via a mediator box (A -> Box -> B).
  dual,
}
