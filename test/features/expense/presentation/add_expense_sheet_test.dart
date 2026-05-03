import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/core/security/device_id_service.dart';
import 'package:plantogether_app/features/expense/domain/entity/expense.dart';
import 'package:plantogether_app/features/expense/domain/repository/expense_repository.dart';
import 'package:plantogether_app/features/expense/presentation/bloc/expense_bloc.dart';
import 'package:plantogether_app/features/expense/presentation/bloc/expense_state.dart';
import 'package:plantogether_app/features/expense/presentation/widget/add_expense_sheet.dart';
import 'package:plantogether_app/features/trip/domain/model/trip_member_model.dart';
import 'package:plantogether_app/features/trip/domain/model/trip_model.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockDeviceIdService extends Mock implements DeviceIdService {}

class FakeRecordExpenseInput extends Fake implements RecordExpenseInput {}

void main() {
  late MockDeviceIdService mockDeviceIdService;

  setUpAll(() {
    registerFallbackValue(FakeRecordExpenseInput());
  });

  setUp(() {
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
    referenceCurrency: 'EUR',
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

  Widget buildSheet(ExpenseBloc bloc) {
    return MaterialApp(
      home: RepositoryProvider<DeviceIdService>.value(
        value: mockDeviceIdService,
        child: BlocProvider.value(
          value: bloc,
          child: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showAddExpenseSheet(
                ctx,
                tripId: tripId,
                trip: sampleTrip,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  group('AddExpenseSheet validation', () {
    testWidgets('missing amount shows required error', (tester) async {
      final bloc = ExpenseBloc(MockExpenseRepository());
      await tester.pumpWidget(buildSheet(bloc));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('expense_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Amount is required'), findsOneWidget);
      expect(bloc.state, const ExpenseState.initial());
    });

    testWidgets('zero amount shows greater than 0 error', (tester) async {
      final bloc = ExpenseBloc(MockExpenseRepository());
      await tester.pumpWidget(buildSheet(bloc));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const ValueKey('expense_amount_field')), '0');
      await tester.tap(find.byKey(const ValueKey('expense_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Amount must be greater than 0'), findsOneWidget);
      expect(bloc.state, const ExpenseState.initial());
    });

    testWidgets('blank description shows required error', (tester) async {
      final bloc = ExpenseBloc(MockExpenseRepository());
      await tester.pumpWidget(buildSheet(bloc));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const ValueKey('expense_amount_field')), '42.00');
      await tester.tap(find.byKey(const ValueKey('expense_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Description is required'), findsOneWidget);
      expect(bloc.state, const ExpenseState.initial());
    });

    testWidgets('valid form dispatches RecordExpense and transitions to loaded',
        (tester) async {
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
      final mockRepo = MockExpenseRepository();
      when(() => mockRepo.record(any(), any()))
          .thenAnswer((_) async => sampleExpense);
      when(() => mockRepo.list(any()))
          .thenAnswer((_) async => pageOf([sampleExpense]));
      final bloc = ExpenseBloc(mockRepo);

      await tester.pumpWidget(buildSheet(bloc));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const ValueKey('expense_amount_field')), '42.00');
      await tester.enterText(
          find.byKey(const ValueKey('expense_description_field')), 'Dinner');
      await tester.tap(find.byKey(const ValueKey('expense_submit_button')));
      await tester.pumpAndSettle();

      expect(
        bloc.state,
        ExpenseState.loaded(
          expenses: [sampleExpense],
          totalElements: 1,
          currentPage: 0,
          hasMore: false,
        ),
      );
    });

    testWidgets('background loaded state does not close sheet', (tester) async {
      final mockRepo = MockExpenseRepository();
      when(() => mockRepo.list(tripId)).thenAnswer((_) async => pageOf([]));
      final bloc = ExpenseBloc(mockRepo);

      await tester.pumpWidget(buildSheet(bloc));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      bloc.emit(const ExpenseState.loaded(
        expenses: [],
        totalElements: 0,
        currentPage: 0,
        hasMore: false,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('expense_amount_field')), findsOneWidget);
    });
  });
}
