import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/core/security/device_id_service.dart';
import 'package:plantogether_app/features/expense/domain/entity/expense.dart';
import 'package:plantogether_app/features/expense/domain/repository/expense_repository.dart';
import 'package:plantogether_app/features/expense/presentation/bloc/expense_bloc.dart';
import 'package:plantogether_app/features/expense/presentation/page/expenses_tab.dart';
import 'package:plantogether_app/features/expense/presentation/widget/expense_card.dart';
import 'package:plantogether_app/features/trip/domain/model/trip_member_model.dart';
import 'package:plantogether_app/features/trip/domain/model/trip_model.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockDeviceIdService extends Mock implements DeviceIdService {}

class FakeRecordExpenseInput extends Fake implements RecordExpenseInput {}

void main() {
  late MockExpenseRepository mockRepository;
  late MockDeviceIdService mockDeviceIdService;

  setUpAll(() {
    registerFallbackValue(FakeRecordExpenseInput());
  });

  setUp(() {
    mockRepository = MockExpenseRepository();
    mockDeviceIdService = MockDeviceIdService();
    when(() => mockDeviceIdService.getOrCreateDeviceId())
        .thenAnswer((_) async => 'device-1');
  });

  ExpensePage pageOf(List<Expense> expenses) => ExpensePage(
        expenses: expenses,
        totalElements: expenses.length,
        totalPages: expenses.isEmpty ? 0 : 1,
        currentPage: 0,
        size: 20,
      );

  const tripId = 'trip-1';
  final sampleTrip = TripModel(
    id: tripId,
    title: 'Paris Trip',
    status: 'ACTIVE',
    createdBy: 'device-1',
    createdAt: DateTime.utc(2026, 4, 1),
    members: [
      TripMemberModel(
        memberId: 'device-1',
        displayName: 'Alice',
        role: 'ORGANIZER',
        joinedAt: DateTime.utc(2026, 4, 1),
        isMe: true,
      ),
    ],
  );

  final sampleExpense = Expense(
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

  Widget buildWidget({required ExpenseBloc bloc}) {
    return MaterialApp(
      home: RepositoryProvider<DeviceIdService>.value(
        value: mockDeviceIdService,
        child: BlocProvider.value(
          value: bloc,
          child: ExpensesTab(tripId: tripId, trip: sampleTrip),
        ),
      ),
    );
  }

  testWidgets('empty state renders correct copy and FAB', (tester) async {
    when(() => mockRepository.list(tripId)).thenAnswer((_) async => pageOf([]));
    final bloc = ExpenseBloc(mockRepository);

    await tester.pumpWidget(buildWidget(bloc: bloc));
    await tester.pumpAndSettle();

    expect(
      find.text('No expenses yet · Add the first expense'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('expenses_add_fab')), findsOneWidget);
  });

  testWidgets('loaded state renders ExpenseCard per expense', (tester) async {
    when(() => mockRepository.list(tripId))
        .thenAnswer((_) async => pageOf([sampleExpense]));
    final bloc = ExpenseBloc(mockRepository);

    await tester.pumpWidget(buildWidget(bloc: bloc));
    await tester.pumpAndSettle();

    expect(find.byType(ExpenseCard), findsOneWidget);
  });

  testWidgets('loading state renders CircularProgressIndicator', (tester) async {
    final completer = Completer<ExpensePage>();
    when(() => mockRepository.list(tripId))
        .thenAnswer((_) async => completer.future);
    final bloc = ExpenseBloc(mockRepository);

    await tester.pumpWidget(buildWidget(bloc: bloc));
    await tester.pump();

    expect(find.byKey(const ValueKey('expenses_loading')), findsOneWidget);
    completer.complete(pageOf([]));
  });

  testWidgets('FAB guard: rapid double-tap opens only one sheet', (tester) async {
    when(() => mockRepository.list(tripId))
        .thenAnswer((_) async => pageOf([sampleExpense]));
    final bloc = ExpenseBloc(mockRepository);

    await tester.pumpWidget(buildWidget(bloc: bloc));
    await tester.pumpAndSettle();

    final fab = find.byKey(const ValueKey('expenses_add_fab'));
    expect(fab, findsOneWidget);

    await tester.tap(fab);
    await tester.tap(fab);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('expense_amount_field')), findsOneWidget);
  });
}
