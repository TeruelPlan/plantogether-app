import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/expense/domain/entity/balance.dart';
import 'package:plantogether_app/features/expense/presentation/bloc/balance/balance_bloc.dart';
import 'package:plantogether_app/features/expense/presentation/bloc/balance/balance_event.dart';
import 'package:plantogether_app/features/expense/presentation/bloc/balance/balance_state.dart';
import 'package:plantogether_app/features/expense/presentation/widget/expense_balance_banner.dart';

class MockBalanceBloc extends MockBloc<BalanceEvent, BalanceState>
    implements BalanceBloc {}

void main() {
  late MockBalanceBloc bloc;
  const me = 'member-a';
  const other = 'member-b';

  setUp(() {
    bloc = MockBalanceBloc();
  });

  Balance balance({
    required double myNet,
    bool allSettled = false,
  }) =>
      Balance(
        tripId: 'trip-1',
        referenceCurrency: 'EUR',
        participantBalances: {me: myNet, other: -myNet},
        settlements: allSettled
            ? const []
            : const [
                SettlementTransfer(
                  fromMemberId: other,
                  toMemberId: me,
                  amount: 50.0,
                  currency: 'EUR',
                ),
              ],
        allSettled: allSettled,
      );

  Future<void> pumpBanner(WidgetTester tester, BalanceState state) async {
    when(() => bloc.state).thenReturn(state);
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<BalanceBloc>.value(
            value: bloc,
            child: ExpenseBalanceBanner(
              myMemberId: me,
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );
    addTearDown(() => tapped);
  }

  testWidgets('positive net shows "You are owed"', (tester) async {
    await pumpBanner(
      tester,
      BalanceState.loaded(balance: balance(myNet: 50.0)),
    );

    expect(find.byKey(const ValueKey('expense_balance_banner')), findsOneWidget);
    expect(find.textContaining('You are owed'), findsOneWidget);
  });

  testWidgets('negative net shows "You owe"', (tester) async {
    await pumpBanner(
      tester,
      BalanceState.loaded(balance: balance(myNet: -50.0)),
    );

    expect(find.textContaining('You owe'), findsOneWidget);
  });

  testWidgets('all settled shows the settled message', (tester) async {
    await pumpBanner(
      tester,
      BalanceState.loaded(balance: balance(myNet: 0.0, allSettled: true)),
    );

    expect(find.textContaining("You're all settled"), findsOneWidget);
  });

  testWidgets('hidden when no balance is loaded', (tester) async {
    await pumpBanner(tester, const BalanceState.initial());

    expect(find.byKey(const ValueKey('expense_balance_banner')), findsNothing);
  });

  testWidgets('tapping the banner invokes onTap', (tester) async {
    when(() => bloc.state)
        .thenReturn(BalanceState.loaded(balance: balance(myNet: 50.0)));
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<BalanceBloc>.value(
            value: bloc,
            child: ExpenseBalanceBanner(
              myMemberId: me,
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('expense_balance_banner_inkwell')));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
