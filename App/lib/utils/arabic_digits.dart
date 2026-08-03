// ─────────────────────────────────────────────────────────────────────────────
// lib/utils/arabic_digits.dart
//
// intl's NumberFormat doesn't reliably switch to Eastern Arabic-Indic digits
// (٠١٢٣٤٥٦٧٨٩) for the generic 'ar' locale — depending on package/version it
// can silently fall back to Western digits, even while DateFormat correctly
// renders Arabic day/month names for the same locale.
//
// This helper sidesteps that entirely: format the number normally (English/
// Western digits), then do a direct character-by-character substitution.
// Guaranteed correct regardless of intl's locale-data quirks.
// ─────────────────────────────────────────────────────────────────────────────

const _western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
const _eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

/// Converts any Western (0-9) digits inside [input] to Eastern Arabic-Indic
/// digits IF [localeCode] is 'ar'. Otherwise returns [input] unchanged.
/// Safe to call on strings that mix digits with other text (e.g. "1,400 EGP",
/// "57%", "17 Jun").
String arDigits(String input, String localeCode) {
  if (localeCode != 'ar') return input;
  var result = input;
  for (var i = 0; i < _western.length; i++) {
    result = result.replaceAll(_western[i], _eastern[i]);
  }
  return result;
}

/// Convenience overload for numeric values — formats with [pattern] decimals
/// (default: no decimals) then converts digits per [localeCode].
String arNumber(num value, String localeCode, {int decimals = 0}) {
  final formatted = value.toStringAsFixed(decimals);
  return arDigits(formatted, localeCode);
}
