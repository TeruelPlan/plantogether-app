import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/expense/domain/entity/expense.dart';
import 'package:plantogether_app/features/expense/domain/entity/expense_breakdown.dart';
import 'package:plantogether_app/features/expense/domain/repository/expense_repository.dart';
import 'package:plantogether_app/features/expense/presentation/bloc/breakdown/expense_breakdown_bloc.dart';
import 'package:plantogether_app/features/expense/presentation/bloc/breakdown/expense_breakdown_event.dart';
import 'package:plantogether_app/features/expense/presentation/bloc/breakdown/expense_breakdown_state.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

void main() {
  late MockExpenseRepository repository;

  setUp(() {
    repository = MockExpenseRepository();
  });

  const tripId = 'trip-1';

  final breakdown = ExpenseBreakdown(
    tripId: tripId,
    referenceCurrency: 'EUR',
    totalAmount: 100.0,
    categories: const [
      CategoryBreakdownEntry(
        category: ExpenseCategory.food,
        totalAmount: 100.0,
        percentage: 100.0,
        expenseCount: 2,
      ),
    ],
  );

  const emptyBreakdown = ExpenseBreakdown(
    tripId: tripId,
    referenceCurrency: 'EUR',
    totalAmount: 0.0,
    categories: [],
  );

  blocTest<ExpenseBreakdownBloc, ExpenseBreakdownState>(
    'loadBreakdown_success_emitsLoaded',
    build: () {
      when(() => repository.getBreakdown(tripId))
          .thenAnswer((_) async => breakdown);
      return ExpenseBreakdownBloc(repository);
    },
    act: (bloc) => bloc.add(const LoadBreakdown(tripId)),
    expect: () => [
      const ExpenseBreakdownState.loading(),
      ExpenseBreakdownState.loaded(breakdown: breakdown),
    ],
  );

  blocTest<ExpenseBreakdownBloc, ExpenseBreakdownState>(
    'loadBreakdown_empty_emitsEmpty',
    build: () {
      when(() => repository.getBreakdown(tripId))
          .thenAnswer((_) async => emptyBreakdown);
      return ExpenseBreakdownBloc(repository);
    },
    act: (bloc) => bloc.add(const LoadBreakdown(tripId)),
    expect: () => [
      const ExpenseBreakdownState.loading(),
      const ExpenseBreakdownState.empty(),
    ],
  );

  blocTest<ExpenseBreakdownBloc, ExpenseBreakdownState>(
    'loadBreakdown_failure_emitsError',
    build: () {
      when(() => repository.getBreakdown(tripId))
          .thenThrow(Exception('Server error. Please try again later'));
      return ExpenseBreakdownBloc(repository);
    },
    act: (bloc) => bloc.add(const LoadBreakdown(tripId)),
    expect: () => [
      const ExpenseBreakdownState.loading(),
      const ExpenseBreakdownState.error(
          message: 'Server error. Please try again later'),
    ],
  );

  blocTest<ExpenseBreakdownBloc, ExpenseBreakdownState>(
    'refreshBreakdown_success_emitsLoaded_withoutLoading',
    build: () {
      when(() => repository.getBreakdown(tripId))
          .thenAnswer((_) async => breakdown);
      return ExpenseBreakdownBloc(repository);
    },
    act: (bloc) => bloc.add(const RefreshBreakdown(tripId)),
    expect: () => [
      ExpenseBreakdownState.loaded(breakdown: breakdown),
    ],
  );
}
