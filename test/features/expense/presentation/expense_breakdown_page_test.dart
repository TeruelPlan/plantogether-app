import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/expense/domain/entity/expense.dart';
import 'package:plantogether_app/features/expense/domain/entity/expense_breakdown.dart';
import 'package:plantogether_app/features/expense/presentation/bloc/breakdown/expense_breakdown_bloc.dart';
import 'package:plantogether_app/features/expense/presentation/bloc/breakdown/expense_breakdown_event.dart';
import 'package:plantogether_app/features/expense/presentation/bloc/breakdown/expense_breakdown_state.dart';
import 'package:plantogether_app/features/expense/presentation/page/expense_breakdown_page.dart';
import 'package:plantogether_app/features/expense/presentation/widget/category_breakdown_tile.dart';
import 'package:plantogether_app/features/expense/presentation/widget/expense_breakdown_chart.dart';

class MockExpenseBreakdownBloc
    extends MockBloc<ExpenseBreakdownEvent, ExpenseBreakdownState>
    implements ExpenseBreakdownBloc {}

void main() {
  late MockExpenseBreakdownBloc bloc;

  const tripId = 'trip-1';

  setUp(() {
    bloc = MockExpenseBreakdownBloc();
  });

  Widget harness() => MaterialApp(
        home: BlocProvider<ExpenseBreakdownBloc>.value(
          value: bloc,
          child: const ExpenseBreakdownPage(tripId: tripId),
        ),
      );

  final loaded = ExpenseBreakdown(
    tripId: tripId,
    referenceCurrency: 'EUR',
    totalAmount: 100.0,
    categories: const [
      CategoryBreakdownEntry(
        category: ExpenseCategory.food,
        totalAmount: 60.0,
        percentage: 60.0,
        expenseCount: 3,
      ),
      CategoryBreakdownEntry(
        category: ExpenseCategory.transport,
        totalAmount: 40.0,
        percentage: 40.0,
        expenseCount: 1,
      ),
    ],
  );

  testWidgets('loading state renders a progress indicator', (tester) async {
    when(() => bloc.state).thenReturn(const ExpenseBreakdownState.loading());

    await tester.pumpWidget(harness());

    expect(
      find.byKey(const ValueKey('expense_breakdown_loading')),
      findsOneWidget,
    );
  });

  testWidgets('empty state renders the empty widget and CTA', (tester) async {
    when(() => bloc.state).thenReturn(const ExpenseBreakdownState.empty());

    await tester.pumpWidget(harness());

    expect(
      find.byKey(const ValueKey('expense_breakdown_empty_state')),
      findsOneWidget,
    );
    expect(find.text('No spending yet'), findsOneWidget);
  });

  testWidgets('loaded state renders the chart and one tile per category',
      (tester) async {
    when(() => bloc.state)
        .thenReturn(ExpenseBreakdownState.loaded(breakdown: loaded));

    await tester.pumpWidget(harness());
    await tester.pump();

    expect(find.byType(ExpenseBreakdownChart), findsOneWidget);
    expect(find.byType(CategoryBreakdownTile), findsNWidgets(2));
  });

  testWidgets('error state renders a retry button', (tester) async {
    when(() => bloc.state)
        .thenReturn(const ExpenseBreakdownState.error(message: 'Boom'));

    await tester.pumpWidget(harness());

    expect(
      find.byKey(const ValueKey('expense_breakdown_retry_button')),
      findsOneWidget,
    );
  });
}
