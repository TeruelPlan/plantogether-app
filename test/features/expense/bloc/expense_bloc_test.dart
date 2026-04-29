import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/expense/domain/entity/expense.dart';
import 'package:plantogether_app/features/expense/domain/repository/expense_repository.dart';
import 'package:plantogether_app/features/expense/presentation/bloc/expense_bloc.dart';
import 'package:plantogether_app/features/expense/presentation/bloc/expense_event.dart';
import 'package:plantogether_app/features/expense/presentation/bloc/expense_state.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class FakeRecordExpenseInput extends Fake implements RecordExpenseInput {}

void main() {
  late MockExpenseRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeRecordExpenseInput());
  });

  setUp(() {
    mockRepository = MockExpenseRepository();
  });

  const tripId = 'trip-1';
  final expense = Expense(
    id: 'exp-1',
    tripId: tripId,
    paidByDeviceId: 'device-1',
    amount: 42.0,
    currency: 'EUR',
    category: ExpenseCategory.food,
    description: 'Dinner',
    splitMode: SplitMode.equal,
    splits: const [],
    createdAt: DateTime.utc(2026, 4, 1),
    updatedAt: DateTime.utc(2026, 4, 1),
  );

  ExpensePage pageOf(List<Expense> expenses) => ExpensePage(
        expenses: expenses,
        totalElements: expenses.length,
        totalPages: expenses.isEmpty ? 0 : 1,
        currentPage: 0,
        size: 20,
      );

  group('ExpenseBloc', () {
    blocTest<ExpenseBloc, ExpenseState>(
      'loadExpenses_success_emitsLoaded',
      build: () {
        when(() => mockRepository.list(tripId)).thenAnswer((_) async => pageOf([expense]));
        return ExpenseBloc(mockRepository);
      },
      act: (bloc) => bloc.add(const LoadExpenses(tripId)),
      expect: () => [
        const ExpenseState.loading(),
        ExpenseState.loaded(
          expenses: [expense],
          totalElements: 1,
          currentPage: 0,
          hasMore: false,
        ),
      ],
    );

    blocTest<ExpenseBloc, ExpenseState>(
      'loadExpenses_failure_emitsError',
      build: () {
        when(() => mockRepository.list(tripId))
            .thenThrow(Exception('Network error'));
        return ExpenseBloc(mockRepository);
      },
      act: (bloc) => bloc.add(const LoadExpenses(tripId)),
      expect: () => [
        const ExpenseState.loading(),
        const ExpenseState.error(message: 'Network error'),
      ],
    );

    blocTest<ExpenseBloc, ExpenseState>(
      'recordExpense_success_reloads',
      build: () {
        when(() => mockRepository.record(any(), any()))
            .thenAnswer((_) async => expense);
        when(() => mockRepository.list(tripId)).thenAnswer((_) async => pageOf([expense]));
        return ExpenseBloc(mockRepository);
      },
      act: (bloc) => bloc.add(RecordExpense(
        tripId: tripId,
        input: const RecordExpenseInput(
          amount: 42.0,
          currency: 'EUR',
          category: ExpenseCategory.food,
          description: 'Dinner',
        ),
      )),
      expect: () => [
        const ExpenseState.loading(),
        ExpenseState.loaded(
          expenses: [expense],
          totalElements: 1,
          currentPage: 0,
          hasMore: false,
        ),
      ],
    );

    blocTest<ExpenseBloc, ExpenseState>(
      'recordExpense_failure_emitsError',
      build: () {
        when(() => mockRepository.record(any(), any()))
            .thenThrow(Exception('Server error'));
        return ExpenseBloc(mockRepository);
      },
      act: (bloc) => bloc.add(RecordExpense(
        tripId: tripId,
        input: const RecordExpenseInput(
          amount: 42.0,
          currency: 'EUR',
          category: ExpenseCategory.food,
          description: 'Dinner',
        ),
      )),
      expect: () => [
        const ExpenseState.loading(),
        const ExpenseState.error(message: 'Server error'),
      ],
    );
  });
}
