/// Classifies the type of income-generating source within the personal
/// financial management module.
///
/// Stored in `Account.metadata['income_source_type']` as a string key
/// to avoid schema migrations.
enum IncomeSourceType {
  /// Physical or financial asset that generates passive income
  /// (real estate, stocks, rental properties).
  /// Classification: `fixedProfitableAssets`
  investmentAsset('investment_asset'),

  /// Personal possession that depreciates over time
  /// (car, furniture, electronics).
  /// Classification: `fixedDepreciableAssets`
  possession('possession'),

  /// Professional work, freelancing, or a trade that generates active income.
  /// Classification: `personalRevenues` (child account with metadata)
  profession('profession'),

  /// Any other income source (rental income, side gig, etc.).
  /// Classification: `personalRevenues` (child account with metadata)
  other('other');

  const IncomeSourceType(this.key);

  /// The string value stored in account metadata.
  final String key;

  /// Resolve from its stored metadata key.
  static IncomeSourceType? fromKey(String? key) {
    if (key == null) return null;
    for (final v in values) {
      if (v.key == key) return v;
    }
    return null;
  }

  /// Whether this type represents an income-generating source
  /// (shown in the Income Streams tab).
  bool get isIncomeGenerating =>
      this == investmentAsset || this == profession || this == other;

  /// The parent classification kind this type belongs to.
  String get parentClassificationKind => switch (this) {
        investmentAsset => 'fixedProfitableAssets',
        possession => 'fixedDepreciableAssets',
        profession => 'personalRevenues',
        other => 'personalRevenues',
      };
}
