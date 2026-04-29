import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantogether_app/features/expense/domain/entity/expense.dart';
import 'package:plantogether_app/features/expense/presentation/widget/expense_detail_sheet.dart';

void main() {
  testWidgets(
      'ExpenseDetailSheet renders all five FX fields with correct formatting',
      (tester) async {
    final expense = Expense(
      id: 'exp-detail-1',
      tripId: 'trip-1',
      paidByDeviceId: 'dev-1',
      amount: 42.0,
      currency: 'USD',
      category: ExpenseCategory.food,
      description: 'Sushi',
      splitMode: SplitMode.equal,
      splits: const [],
      createdAt: DateTime.utc(2026, 4, 28),
      updatedAt: DateTime.utc(2026, 4, 28),
      exchangeRate: 0.92154321,
      amountInReferenceCurrency: 38.7048,
      referenceCurrency: 'EUR',
      rateSource: RateSource.fallback,
      rateFetchedAt: DateTime.utc(2026, 4, 27, 9, 30),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ExpenseDetailSheet(
          expense: expense,
          payerDisplayName: 'Alice',
        ),
      ),
    ));

    // Original amount
    expect(find.byKey(const ValueKey('expense_detail_amount')), findsOneWidget);
    expect(find.textContaining('USD'), findsWidgets);
    expect(find.textContaining('42.00'), findsOneWidget);

    // Converted amount
    expect(find.byKey(const ValueKey('expense_detail_converted')),
        findsOneWidget);
    expect(find.textContaining('38.70'), findsOneWidget);

    // Exchange rate (4dp)
    expect(find.byKey(const ValueKey('expense_detail_rate')), findsOneWidget);
    expect(find.textContaining('0.9215'), findsOneWidget);

    // Rate source label
    expect(find.byKey(const ValueKey('expense_detail_rate_source')),
        findsOneWidget);
    expect(find.text('Cached fallback'), findsOneWidget);

    // Rate fetched at — UTC formatted
    expect(find.byKey(const ValueKey('expense_detail_rate_fetched_at')),
        findsOneWidget);
    expect(find.textContaining('2026-04-27 09:30 UTC'), findsOneWidget);
  });
}
