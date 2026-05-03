import 'package:flutter/material.dart';

import '../../../../core/constants/currencies.dart';

/// Currency dropdown for the expense form (Story 5.2 AC-1, AC-9).
///
/// Renders the 5 MVP currencies in fixed order. Default value should be the
/// trip's `referenceCurrency`. The dropdown is the only allowed input — the
/// form CANNOT submit anything outside [SupportedCurrencies.all].
class CurrencySelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  const CurrencySelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final effective = SupportedCurrencies.isSupported(value)
        ? value
        : SupportedCurrencies.all.first;
    return DropdownButtonFormField<String>(
      key: const ValueKey('expense_currency_dropdown'),
      value: effective,
      decoration: const InputDecoration(
        labelText: 'Currency',
        border: OutlineInputBorder(),
      ),
      items: SupportedCurrencies.all
          .map(
            (code) => DropdownMenuItem<String>(
              key: ValueKey('expense_currency_item_$code'),
              value: code,
              child: Text(code),
            ),
          )
          .toList(),
      onChanged: enabled
          ? (v) {
              if (v != null) onChanged(v);
            }
          : null,
    );
  }
}
