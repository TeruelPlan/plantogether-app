/// Supported MVP currencies for multi-currency expense entry.
///
/// Order is fixed and matches the backend `@AllowedCurrencies` allow-list.
/// Single source of truth — used by the currency selector and validation.
class SupportedCurrencies {
  SupportedCurrencies._();

  static const List<String> all = ['EUR', 'USD', 'GBP', 'CHF', 'JPY'];

  static bool isSupported(String code) => all.contains(code);
}
