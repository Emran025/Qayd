/// Validated BIP39 mnemonic phrase — the user's cryptographic identity seed.
///
/// Exactly 24 words (256-bit entropy). Same seed always regenerates the same
/// Ed25519 key pair.
final class MnemonicPhrase {
  MnemonicPhrase(this.words) {
    if (words.length != wordCount) {
      throw ArgumentError.value(
        words.length,
        'words',
        'Mnemonic must contain exactly $wordCount words, got ${words.length}.',
      );
    }
    for (final w in words) {
      if (w.trim().isEmpty) {
        throw ArgumentError.value(w, 'word', 'Mnemonic words must not be blank.');
      }
    }
  }

  /// Standard BIP39 word count for 256-bit entropy.
  static const int wordCount = 24;

  /// The ordered list of mnemonic words.
  final List<String> words;

  /// Space-separated phrase for display and serialization.
  String get phrase => words.join(' ');

  /// Reconstructs from a space-separated phrase string.
  factory MnemonicPhrase.fromPhrase(String phrase) {
    final cleaned = phrase.trim().split(RegExp(r'\s+'));
    return MnemonicPhrase(cleaned);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MnemonicPhrase && phrase == other.phrase;

  @override
  int get hashCode => phrase.hashCode;

  @override
  String toString() => 'MnemonicPhrase(${words.length} words)';
}
