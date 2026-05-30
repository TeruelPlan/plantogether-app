import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/expense/domain/entity/balance.dart';
import 'package:plantogether_app/features/expense/presentation/bloc/balance/balance_bloc.dart';
import 'package:plantogether_app/features/expense/presentation/bloc/balance/balance_event.dart';
import 'package:plantogether_app/features/expense/presentation/bloc/balance/balance_state.dart';
import 'package:plantogether_app/features/expense/presentation/widget/settlement_arrows_widget.dart';
import 'package:plantogether_app/features/trip/domain/model/trip_member_model.dart';
import 'package:plantogether_app/features/trip/domain/model/trip_model.dart';

class MockBalanceBloc extends MockBloc<BalanceEvent, BalanceState>
    implements BalanceBloc {}

void main() {
  late MockBalanceBloc bloc;

  const tripId = 'trip-1';
  const me = 'member-a';
  const other = 'member-b';

  final trip = TripModel(
    id: tripId,
    title: 'Paris',
    status: 'ACTIVE',
    referenceCurrency: 'EUR',
    createdBy: me,
    createdAt: DateTime.utc(2026, 4, 1),
    members: [
      TripMemberModel(
        memberId: me,
        displayName: 'Alice',
        role: 'ORGANIZER',
        joinedAt: DateTime.utc(2026, 4, 1),
        isMe: true,
      ),
      TripMemberModel(
        memberId: other,
        displayName: 'Bob',
        role: 'PARTICIPANT',
        joinedAt: DateTime.utc(2026, 4, 1),
        isMe: false,
      ),
    ],
  );

  const pendingTransfer = SettlementTransfer(
    fromMemberId: other,
    toMemberId: me,
    amount: 50.0,
    currency: 'EUR',
  );

  setUp(() {
    bloc = MockBalanceBloc();
  });

  Widget harness() => MaterialApp(
        home: Scaffold(
          body: BlocProvider<BalanceBloc>.value(
            value: bloc,
            child: SettlementArrowsWidget(
              trip: trip,
              tripId: tripId,
              myMemberId: me,
              variant: SettlementVariant.fullScreen,
            ),
          ),
        ),
      );

  testWidgets('renders one row per settlement', (tester) async {
    when(() => bloc.state).thenReturn(
      BalanceState.loaded(
        balance: Balance(
          tripId: tripId,
          referenceCurrency: 'EUR',
          participantBalances: const {me: 50.0, other: -50.0},
          settlements: const [pendingTransfer],
        ),
      ),
    );

    await tester.pumpWidget(harness());

    expect(
      find.byKey(ValueKey('settlement-row-$other-$me-50.0')),
      findsOneWidget,
    );
  });

  testWidgets('shows a Mark done button on a pending row', (tester) async {
    when(() => bloc.state).thenReturn(
      BalanceState.loaded(
        balance: Balance(
          tripId: tripId,
          referenceCurrency: 'EUR',
          participantBalances: const {me: 50.0, other: -50.0},
          settlements: const [pendingTransfer],
        ),
      ),
    );

    await tester.pumpWidget(harness());

    expect(
      find.byKey(ValueKey('settlement-mark-done-$other-$me-50.0')),
      findsOneWidget,
    );
  });

  testWidgets('shows the balanced placeholder when there are no settlements',
      (tester) async {
    when(() => bloc.state).thenReturn(
      const BalanceState.loaded(
        balance: Balance(
          tripId: tripId,
          referenceCurrency: 'EUR',
          participantBalances: {},
          settlements: [],
        ),
      ),
    );

    await tester.pumpWidget(harness());

    expect(
      find.byKey(const ValueKey('settlement_balanced_placeholder')),
      findsOneWidget,
    );
  });

  testWidgets('shows the all-done state when every transfer is settled',
      (tester) async {
    when(() => bloc.state).thenReturn(
      BalanceState.loaded(
        balance: Balance(
          tripId: tripId,
          referenceCurrency: 'EUR',
          participantBalances: const {me: 50.0, other: -50.0},
          settlements: const [
            SettlementTransfer(
              fromMemberId: other,
              toMemberId: me,
              amount: 50.0,
              currency: 'EUR',
              status: SettlementStatus.done,
            ),
          ],
          allSettled: true,
        ),
      ),
    );

    await tester.pumpWidget(harness());

    expect(find.byKey(const ValueKey('settlement_all_done')), findsOneWidget);
    // No mark-done button on a settled row.
    expect(
      find.byKey(ValueKey('settlement-mark-done-$other-$me-50.0')),
      findsNothing,
    );
  });
}
