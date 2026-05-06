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

class _FakeUpdateInput extends Fake implements UpdateExpenseInput {}

void main() {
  late _MockExpenseRepository repository;

  setUpAll(() {
    registerFallbackValue(_FakeUpdateInput());
  });

  setUp(() {
    repository = _MockExpenseRepository();
  });

  const tripId = 'trip-1';
  Expense expense(String id) => Expense(
        id: id,
        tripId: tripId,
        paidByDeviceId: 'device-1',
        amount: 50,
        currency: 'EUR',
        category: ExpenseCategory.food,
        description: 'Dinner',
        splitMode: SplitMode.equal,
        splits: const [],
        createdAt: DateTime.utc(2026, 4, 1),
        updatedAt: DateTime.utc(2026, 4, 1),
      );

  final list = [expense('e-1'), expense('e-2')];
  ExpensePage page() => ExpensePage(
        expenses: list,
        totalElements: list.length,
        totalPages: 1,
        currentPage: 0,
        size: 20,
      );
  ExpenseState seedLoaded() => ExpenseState.loaded(
        expenses: list,
        totalElements: list.length,
        currentPage: 0,
        hasMore: false,
      );

  UpdateExpenseInput input() => const UpdateExpenseInput(
        amount: 60,
        currency: 'EUR',
        category: ExpenseCategory.food,
        description: 'Dinner edited',
      );

  group('UpdateExpense', () {
    blocTest<ExpenseBloc, ExpenseState>(
      'success → reloads list',
      setUp: () {
        when(() => repository.updateExpense(any(), any()))
            .thenAnswer((_) async => expense('e-1'));
        when(() => repository.list(tripId)).thenAnswer((_) async => page());
      },
      build: () => ExpenseBloc(repository),
      seed: seedLoaded,
      act: (b) => b.add(UpdateExpense(
          tripId: tripId, expenseId: 'e-1', input: input())),
      verify: (_) =>
          verify(() => repository.updateExpense('e-1', any())).called(1),
    );

    blocTest<ExpenseBloc, ExpenseState>(
      '403 → emits submitFailed and reloads list',
      setUp: () {
        when(() => repository.updateExpense(any(), any())).thenThrow(
            const ExpenseSubmitError(message: 'forbidden', statusCode: 403));
        when(() => repository.list(tripId)).thenAnswer((_) async => page());
      },
      build: () => ExpenseBloc(repository),
      seed: seedLoaded,
      act: (b) => b.add(UpdateExpense(
          tripId: tripId, expenseId: 'e-1', input: input())),
      verify: (_) {
        verify(() => repository.updateExpense('e-1', any())).called(1);
        verify(() => repository.list(tripId)).called(1);
      },
    );

    blocTest<ExpenseBloc, ExpenseState>(
      '404 → emits submitFailed and reloads list',
      setUp: () {
        when(() => repository.updateExpense(any(), any())).thenThrow(
            const ExpenseSubmitError(message: 'gone', statusCode: 404));
        when(() => repository.list(tripId)).thenAnswer((_) async => page());
      },
      build: () => ExpenseBloc(repository),
      seed: seedLoaded,
      act: (b) => b.add(UpdateExpense(
          tripId: tripId, expenseId: 'e-1', input: input())),
      verify: (_) {
        verify(() => repository.updateExpense('e-1', any())).called(1);
        verify(() => repository.list(tripId)).called(1);
      },
    );

    blocTest<ExpenseBloc, ExpenseState>(
      '400 → emits submitFailed without reload',
      setUp: () {
        when(() => repository.updateExpense(any(), any())).thenThrow(
            const ExpenseSubmitError(message: 'bad', statusCode: 400));
      },
      build: () => ExpenseBloc(repository),
      seed: seedLoaded,
      act: (b) => b.add(UpdateExpense(
          tripId: tripId, expenseId: 'e-1', input: input())),
      verify: (_) {
        verify(() => repository.updateExpense('e-1', any())).called(1);
        verifyNever(() => repository.list(tripId));
      },
    );
  });

  group('DeleteExpense', () {
    blocTest<ExpenseBloc, ExpenseState>(
      'success → optimistic remove then reload',
      setUp: () {
        when(() => repository.deleteExpense(any())).thenAnswer((_) async {});
        when(() => repository.list(tripId)).thenAnswer((_) async => page());
      },
      build: () => ExpenseBloc(repository),
      seed: seedLoaded,
      act: (b) => b.add(DeleteExpense(tripId: tripId, expenseId: 'e-1')),
      verify: (bloc) {
        verify(() => repository.deleteExpense('e-1')).called(1);
        verify(() => repository.list(tripId)).called(1);
      },
    );

    blocTest<ExpenseBloc, ExpenseState>(
      '403 → rolls back to original list and emits submitFailed',
      setUp: () {
        when(() => repository.deleteExpense(any())).thenThrow(
            const ExpenseSubmitError(message: 'forbidden', statusCode: 403));
      },
      build: () => ExpenseBloc(repository),
      seed: seedLoaded,
      act: (b) => b.add(DeleteExpense(tripId: tripId, expenseId: 'e-1')),
      verify: (bloc) {
        verify(() => repository.deleteExpense('e-1')).called(1);
        // Last emitted state should restore e-1 (rollback).
        final restored = bloc.state.maybeWhen(
          submitFailed: (_, expenses, __, ___, ____) =>
              expenses.any((e) => e.id == 'e-1'),
          orElse: () => false,
        );
        expect(restored, isTrue);
      },
    );

    blocTest<ExpenseBloc, ExpenseState>(
      '404 → keeps optimistic removal and reloads',
      setUp: () {
        when(() => repository.deleteExpense(any())).thenThrow(
            const ExpenseSubmitError(message: 'gone', statusCode: 404));
        when(() => repository.list(tripId)).thenAnswer((_) async => page());
      },
      build: () => ExpenseBloc(repository),
      seed: seedLoaded,
      act: (b) => b.add(DeleteExpense(tripId: tripId, expenseId: 'e-1')),
      verify: (_) {
        verify(() => repository.deleteExpense('e-1')).called(1);
        verify(() => repository.list(tripId)).called(1);
      },
    );
  });
}
