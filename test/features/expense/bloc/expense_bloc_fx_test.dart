import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/expense/domain/entity/expense.dart';
import 'package:plantogether_app/features/expense/domain/entity/expense_submit_error.dart';
import 'package:plantogether_app/features/expense/domain/repository/expense_repository.dart';
import 'package:plantogether_app/features/expense/presentation/bloc/expense_bloc.dart';
import 'package:plantogether_app/features/expense/presentation/bloc/expense_event.dart';
import 'package:plantogether_app/features/expense/presentation/bloc/expense_state.dart';

class _MockExpenseRepository extends Mock implements ExpenseRepository {}

class _FakeRecordExpenseInput extends Fake implements RecordExpenseInput {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeRecordExpenseInput());
  });

  late _MockExpenseRepository repo;

  const tripId = 'trip-1';

  Expense fxExpense({
    RateSource source = RateSource.fallback,
  }) {
    return Expense(
      id: 'exp-fx-1',
      tripId: tripId,
      paidByDeviceId: 'device-1',
      amount: 42.0,
      currency: 'USD',
      category: ExpenseCategory.food,
      description: 'Sushi',
      splitMode: SplitMode.equal,
      splits: const [],
      createdAt: DateTime.utc(2026, 4, 28),
      updatedAt: DateTime.utc(2026, 4, 28),
      exchangeRate: 0.9215,
      amountInReferenceCurrency: 38.7030,
      referenceCurrency: 'EUR',
      rateSource: source,
      rateFetchedAt: DateTime.utc(2026, 4, 27, 9, 0),
    );
  }

  ExpensePage pageOf(List<Expense> expenses) => ExpensePage(
        expenses: expenses,
        totalElements: expenses.length,
        totalPages: expenses.isEmpty ? 0 : 1,
        currentPage: 0,
        size: 20,
      );

  setUp(() {
    repo = _MockExpenseRepository();
  });

  const input = RecordExpenseInput(
    amount: 42.0,
    currency: 'USD',
    category: ExpenseCategory.food,
    description: 'Sushi',
  );

  group('ExpenseBloc — FX paths', () {
    blocTest<ExpenseBloc, ExpenseState>(
      'createExpense_fallbackRate_persistsInResponse',
      build: () {
        final fallback = fxExpense(source: RateSource.fallback);
        when(() => repo.record(any(), any()))
            .thenAnswer((_) async => fallback);
        when(() => repo.list(tripId))
            .thenAnswer((_) async => pageOf([fallback]));
        return ExpenseBloc(repo);
      },
      act: (bloc) =>
          bloc.add(const RecordExpense(tripId: tripId, input: input)),
      verify: (_) {
        verify(() => repo.record(tripId, any())).called(1);
      },
      expect: () => [
        const ExpenseState.loading(),
        isA<ExpenseState>().having(
          (s) => s.maybeWhen(
            loaded: (expenses, _, __, ___) =>
                expenses.first.rateSource == RateSource.fallback &&
                expenses.first.amountInReferenceCurrency == 38.7030,
            orElse: () => false,
          ),
          'loaded with fallback expense',
          true,
        ),
      ],
    );

    blocTest<ExpenseBloc, ExpenseState>(
      'createExpense_503_emitsSubmitError_keepsFormState',
      build: () {
        when(() => repo.record(any(), any())).thenThrow(
          const ExpenseSubmitError(
            message:
                'Exchange rate unavailable for USD → EUR. Try again or change currency.',
            statusCode: 503,
            isFxUnavailable: true,
            baseCurrency: 'USD',
            quoteCurrency: 'EUR',
          ),
        );
        return ExpenseBloc(repo);
      },
      act: (bloc) =>
          bloc.add(const RecordExpense(tripId: tripId, input: input)),
      expect: () => [
        const ExpenseState.loading(),
        isA<ExpenseState>().having(
          (s) => s.maybeWhen(
            submitFailed: (error, _, __, ___, ____) =>
                error.isFxUnavailable && error.statusCode == 503,
            orElse: () => false,
          ),
          'submitFailed with FX 503',
          true,
        ),
      ],
      verify: (_) {
        // List is NOT reloaded on submit failure — form state preserved.
        verifyNever(() => repo.list(any()));
      },
    );
  });
}
