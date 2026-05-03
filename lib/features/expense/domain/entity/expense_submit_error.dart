/// Submit-time error surfaced to the expense form.
///
/// Carries enough information to render the AC-5 inline error
/// ("Exchange rate unavailable for {BASE} → {QUOTE}") without losing
/// user input.
class ExpenseSubmitError implements Exception {
  final String message;

  /// HTTP status code returned by the backend, when known.
  final int? statusCode;

  /// `true` when the backend signalled `503 Service Unavailable` because the
  /// FX rate could not be resolved (live + cached + last-known all missed).
  final bool isFxUnavailable;

  /// ISO 4217 base currency (the originalCurrency the user picked).
  final String? baseCurrency;

  /// ISO 4217 quote currency (the trip's referenceCurrency).
  final String? quoteCurrency;

  const ExpenseSubmitError({
    required this.message,
    this.statusCode,
    this.isFxUnavailable = false,
    this.baseCurrency,
    this.quoteCurrency,
  });

  @override
  String toString() => 'ExpenseSubmitError($statusCode): $message';
}
