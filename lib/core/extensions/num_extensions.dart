extension NumExtensions on num {
  bool get isEffectivelyZero => abs() < 1e-12;
}
