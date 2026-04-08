/// Built-in chart-of-accounts classifications from the accounting equation.
enum StandardAccountClassificationKind {
  liquidAssets,
  receivables,
  payables,
  settlements,
  clearingRemittances, // System glass account for remittances
  remittanceFees,      // System profit center for remittance fees
  personalExpenses,
  personalRevenues,
  fixedDepreciableAssets, // أصول ثابتة (مهلكة)
  fixedProfitableAssets,  // أصول ثابتة (ربحية)
}
