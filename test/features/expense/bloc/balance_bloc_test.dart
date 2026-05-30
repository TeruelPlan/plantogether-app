import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/expense/domain/entity/balance.dart';
import 'package:plantogether_app/features/expense/domain/repository/balance_repository.dart';
import 'package:plantogether_app/features/expense/presentation/bloc/balance/balance_bloc.dart';
import 'package:plantogether_app/features/expense/presentation/bloc/balance/balance_event.dart';
import 'package:plantogether_app/features/expense/presentation/bloc/balance/balance_state.dart';

class MockBalanceRepository extends Mock implements BalanceRepository {}

void main() {
  late MockBalanceRepository repository;

  setUpAll(() {
    registerFallbackValue(
      const SettlementTransfer(
        fromMemberId: 'x',
        toMemberId: 'y',
        amount: 1.0,
        currency: 'EUR',
      ),
    );
  });

  setUp(() {
    repository = MockBalanceRepository();
  });

  const tripId = 'trip-1';
  const me = 'member-a';
  const other = 'member-b';

  const transfer = SettlementTransfer(
    fromMemberId: other,
    toMemberId: me,
    amount: 50.0,
    currency: 'EUR',
  );

  Balance balanceWith(SettlementStatus status) => Balance(
        tripId: tripId,
        referenceCurrency: 'EUR',
        participantBalances: const {me: 50.0, other: -50.0},
        settlements: [transfer.copyWith(status: status)],
        allSettled: status == SettlementStatus.done,
      );

  group('LoadBalance', () {
    blocTest<BalanceBloc, BalanceState>(
      'emits [loading, loaded] on success',
      build: () {
        when(() => repository.getBalance(tripId))
            .thenAnswer((_) async => balanceWith(SettlementStatus.pending));
        return BalanceBloc(repository);
      },
      act: (bloc) => bloc.add(const LoadBalance(tripId)),
      expect: () => [
        const BalanceState.loading(),
        BalanceState.loaded(balance: balanceWith(SettlementStatus.pending)),
      ],
    );

    blocTest<BalanceBloc, BalanceState>(
      'emits [loading, error] on failure',
      build: () {
        when(() => repository.getBalance(tripId))
            .thenThrow(Exception('Network error'));
        return BalanceBloc(repository);
      },
      act: (bloc) => bloc.add(const LoadBalance(tripId)),
      expect: () => [
        const BalanceState.loading(),
        const BalanceState.error(message: 'Network error'),
      ],
    );

    blocTest<BalanceBloc, BalanceState>(
      'droppable transformer ignores an in-flight retrigger',
      build: () {
        when(() => repository.getBalance(tripId)).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return balanceWith(SettlementStatus.pending);
        });
        return BalanceBloc(repository);
      },
      act: (bloc) => bloc
        ..add(const LoadBalance(tripId))
        ..add(const LoadBalance(tripId)),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(() => repository.getBalance(tripId)).called(1);
      },
    );
  });

  group('MarkTransferDone', () {
    blocTest<BalanceBloc, BalanceState>(
      'optimistically flips to DONE then reloads on success',
      build: () {
        when(() => repository.markTransferDone(tripId, any()))
            .thenAnswer((_) async {});
        when(() => repository.getBalance(tripId))
            .thenAnswer((_) async => balanceWith(SettlementStatus.done));
        return BalanceBloc(repository);
      },
      seed: () => BalanceState.loaded(balance: balanceWith(SettlementStatus.pending)),
      act: (bloc) =>
          bloc.add(const MarkTransferDone(tripId: tripId, transfer: transfer)),
      expect: () => [
        // optimistic DONE
        BalanceState.loaded(balance: balanceWith(SettlementStatus.done)),
        // reload: loading then loaded(done)
        const BalanceState.loading(),
        BalanceState.loaded(balance: balanceWith(SettlementStatus.done)),
      ],
      verify: (_) {
        verify(() => repository.markTransferDone(tripId, any())).called(1);
      },
    );

    blocTest<BalanceBloc, BalanceState>(
      'rolls back to PENDING and emits error on failure',
      build: () {
        when(() => repository.markTransferDone(tripId, any()))
            .thenThrow(Exception('The settlement plan changed. Please refresh'));
        return BalanceBloc(repository);
      },
      seed: () => BalanceState.loaded(balance: balanceWith(SettlementStatus.pending)),
      act: (bloc) =>
          bloc.add(const MarkTransferDone(tripId: tripId, transfer: transfer)),
      expect: () => [
        BalanceState.loaded(balance: balanceWith(SettlementStatus.done)),
        BalanceState.loaded(balance: balanceWith(SettlementStatus.pending)),
        const BalanceState.error(
            message: 'The settlement plan changed. Please refresh'),
      ],
    );
  });
}
