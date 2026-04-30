import 'package:qayd/core/constants/countries_names.dart';

/// WhatsApp-style phone number normalization service.
///
/// Converts local phone numbers to E.164 international format by extracting
/// the country code from the **owner's own registered phone number** — exactly
/// like WhatsApp does: any contact saved without a `+` prefix is assumed to
/// belong to the same country as the user.
class PhoneNormalizationService {
  /// Creates the service. [ownerPhone] is the user's own verified phone number
  /// (from `licenseData['phone']`), already in international format (e.g.
  /// `967773456789` or `+967773456789`).
  const PhoneNormalizationService({required this.ownerPhone});

  /// The owner's phone in international digits (no `+`).
  final String ownerPhone;

  /// The country dial code extracted from the owner's phone number.
  /// Returns empty string if it cannot be determined.
  String get ownerCountryCode => _extractCountryCode(ownerPhone);

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Normalizes [raw] to E.164 format (e.g. `+967773456789`).
  ///
  /// Rules (same as WhatsApp):
  /// 1. Already starts with `+`  → clean and return.
  /// 2. Starts with `00`         → replace with `+` and return.
  /// 3. Starts with `0` (trunk)  → strip the `0`, prepend `+countryCode`.
  /// 4. No prefix                → prepend `+countryCode` directly.
  String normalize(String raw) {
    if (raw.isEmpty) return raw;

    // Remove whitespace, dashes, parentheses — keep only digits and +.
    var cleaned = raw.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Case 1: International with +
    if (cleaned.startsWith('+')) {
      return _cleanInternational(cleaned);
    }

    // Case 2: International with 00
    if (cleaned.startsWith('00')) {
      return _cleanInternational('+${cleaned.substring(2)}');
    }

    // For cases 3 & 4 we need the owner's country code.
    final code = ownerCountryCode;
    if (code.isEmpty) {
      // Can't determine country — return as-is with a +
      return '+$cleaned';
    }

    // Case 3: Local with trunk prefix (0)
    if (cleaned.startsWith('0')) {
      return '+$code${cleaned.substring(1)}';
    }

    // Case 4: Local without any prefix
    // Check that the number doesn't already start with the country code
    // (e.g. someone stored 967773456789 without the +)
    if (cleaned.startsWith(code) && cleaned.length > code.length + 5) {
      return '+$cleaned';
    }

    return '+$code$cleaned';
  }

  /// Normalizes the number and strips the leading `+` — useful for storage
  /// where we don't want the plus sign (matches the existing convention in
  /// party_details / wa.me links).
  String normalizeDigitsOnly(String raw) {
    final e164 = normalize(raw);
    return e164.startsWith('+') ? e164.substring(1) : e164;
  }

  // ── Private Helpers ─────────────────────────────────────────────────────────

  /// Cleans an international number (already has `+`).
  String _cleanInternational(String phone) {
    // Only keep digits after the +
    final digits = phone.substring(1).replaceAll(RegExp(r'\D'), '');
    return '+$digits';
  }

  /// Extracts the country dial code from a full phone number by matching
  /// against the known countries list. Tries longest match first.
  String _extractCountryCode(String phone) {
    if (phone.isEmpty) return '';

    // Remove + if present, and all non-digit chars.
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';

    // Build a sorted list of dial codes (longest first) to greedily match.
    final codes = <String>[];
    for (final c in countries) {
      final code = c.countryCallingCode.replaceAll(RegExp(r'\D'), '');
      if (code.isNotEmpty) codes.add(code);
    }
    // Sort descending by length so we match the most specific code first.
    codes.sort((a, b) => b.length.compareTo(a.length));

    for (final code in codes) {
      if (digits.startsWith(code)) {
        return code;
      }
    }

    // Fallback: unable to determine.
    return '';
  }
}
