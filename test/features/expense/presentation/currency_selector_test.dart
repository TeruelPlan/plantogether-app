import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantogether_app/core/constants/currencies.dart';
import 'package:plantogether_app/features/expense/presentation/widget/currency_selector.dart';

void main() {
  group('CurrencySelector', () {
    testWidgets('shows exactly the 5 MVP currencies in fixed order',
        (tester) async {
      String selected = 'EUR';
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CurrencySelector(
            value: selected,
            onChanged: (v) => selected = v,
          ),
        ),
      ));

      await tester.tap(find.byKey(const ValueKey('expense_currency_dropdown')));
      await tester.pumpAndSettle();

      // Each item key should be present.
      for (final code in SupportedCurrencies.all) {
        expect(
          find.byKey(ValueKey('expense_currency_item_$code')),
          findsWidgets,
          reason: 'Missing currency $code',
        );
      }
      expect(SupportedCurrencies.all,
          equals(const ['EUR', 'USD', 'GBP', 'CHF', 'JPY']));
    });

    testWidgets('default value equals the mocked trip reference currency',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CurrencySelector(
            value: 'JPY',
            onChanged: (_) {},
          ),
        ),
      ));
      // The selected value renders in the closed dropdown.
      expect(find.text('JPY'), findsOneWidget);
    });

    testWidgets('falls back to first currency when value is unsupported',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CurrencySelector(
            value: 'XXX',
            onChanged: (_) {},
          ),
        ),
      ));
      expect(find.text('EUR'), findsOneWidget);
    });
  });
}
