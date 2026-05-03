import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantogether_app/features/expense/domain/entity/expense.dart';
import 'package:plantogether_app/features/expense/presentation/widget/expense_card.dart';

Expense _make({
  required String currency,
  String? referenceCurrency,
  RateSource source = RateSource.live,
  double exchangeRate = 1.0,
  double? amountInReferenceCurrency,
  DateTime? rateFetchedAt,
}) {
  return Expense(
    id: 'exp-1',
    tripId: 'trip-1',
    paidByDeviceId: 'dev-1',
    amount: 42.0,
    currency: currency,
    category: ExpenseCategory.food,
    description: 'Dinner',
    splitMode: SplitMode.equal,
    splits: const [],
    createdAt: DateTime.utc(2026, 4, 28),
    updatedAt: DateTime.utc(2026, 4, 28),
    exchangeRate: exchangeRate,
    amountInReferenceCurrency: amountInReferenceCurrency,
    referenceCurrency: referenceCurrency,
    rateSource: source,
    rateFetchedAt: rateFetchedAt,
  );
}

Future<void> _pump(WidgetTester tester, Expense expense) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: ExpenseCard(expense: expense, payerDisplayName: 'Alice'),
    ),
  ));
}

void main() {
  group('ExpenseCard dual amount', () {
    testWidgets('same-currency expense shows no secondary line and no chip',
        (tester) async {
      final e = _make(currency: 'EUR', referenceCurrency: 'EUR');
      await _pump(tester, e);

      expect(find.byKey(const ValueKey('expense_card_converted_exp-1')),
          findsNothing);
      expect(find.byKey(const ValueKey('expense_card_fallback_chip_exp-1')),
          findsNothing);
    });

    testWidgets(
        'foreign-currency LIVE shows secondary line and no fallback chip',
        (tester) async {
      final e = _make(
        currency: 'USD',
        referenceCurrency: 'EUR',
        source: RateSource.live,
        exchangeRate: 0.92,
        amountInReferenceCurrency: 38.64,
      );
      await _pump(tester, e);

      expect(find.byKey(const ValueKey('expense_card_converted_exp-1')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('expense_card_fallback_chip_exp-1')),
          findsNothing);
      expect(find.textContaining('≈'), findsOneWidget);
    });

    testWidgets(
        'foreign-currency FALLBACK shows secondary line and warning chip',
        (tester) async {
      final e = _make(
        currency: 'USD',
        referenceCurrency: 'EUR',
        source: RateSource.fallback,
        exchangeRate: 0.92,
        amountInReferenceCurrency: 38.64,
        rateFetchedAt: DateTime.utc(2026, 4, 20, 10, 0),
      );
      await _pump(tester, e);

      expect(find.byKey(const ValueKey('expense_card_converted_exp-1')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('expense_card_fallback_chip_exp-1')),
          findsOneWidget);
      expect(find.textContaining('Using cached rate from 2026-04-20'), findsOneWidget);
    });
  });
}
