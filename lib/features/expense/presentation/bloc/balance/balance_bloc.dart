import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entity/balance.dart';
import '../../../domain/repository/balance_repository.dart';
import 'balance_event.dart';
import 'balance_state.dart';

class BalanceBloc extends Bloc<BalanceEvent, BalanceState> {
  final BalanceRepository _repository;

  BalanceBloc(this._repository) : super(const BalanceState.initial()) {
    on<LoadBalance>(_onLoad, transformer: droppable());
    on<MarkTransferDone>(_onMarkTransferDone, transformer: droppable());
  }

  Future<void> _onLoad(LoadBalance event, Emitter<BalanceState> emit) async {
    emit(const BalanceState.loading());
    try {
      final balance = await _repository.getBalance(event.tripId);
      if (emit.isDone) return;
      emit(BalanceState.loaded(balance: balance));
    } on Exception catch (e) {
      if (emit.isDone) return;
      emit(BalanceState.error(message: _readableMessage(e)));
    }
  }

  Future<void> _onMarkTransferDone(
    MarkTransferDone event,
    Emitter<BalanceState> emit,
  ) async {
    final currentBalance = state.maybeWhen(
      loaded: (balance) => balance,
      orElse: () => null,
    );
    if (currentBalance == null) return;

    // Optimistically flip the targeted row to DONE.
    final optimistic = _withTransferStatus(
      currentBalance,
      event.transfer,
      SettlementStatus.done,
    );
    emit(BalanceState.loaded(balance: optimistic));

    try {
      await _repository.markTransferDone(event.tripId, event.transfer);
      if (emit.isDone) return;
      // Reload so the canonical merge happens server-side.
      add(LoadBalance(event.tripId));
    } on Exception catch (e) {
      if (emit.isDone) return;
      // Roll back to PENDING, then surface the error.
      emit(BalanceState.loaded(balance: currentBalance));
      emit(BalanceState.error(message: _readableMessage(e)));
    }
  }

  Balance _withTransferStatus(
    Balance balance,
    SettlementTransfer target,
    SettlementStatus status,
  ) {
    final updated = [
      for (final t in balance.settlements)
        if (_sameTransfer(t, target)) t.copyWith(status: status) else t,
    ];
    final allSettled = updated.isEmpty ||
        updated.every((t) => t.status == SettlementStatus.done);
    return balance.copyWith(settlements: updated, allSettled: allSettled);
  }

  bool _sameTransfer(SettlementTransfer a, SettlementTransfer b) =>
      a.fromMemberId == b.fromMemberId &&
      a.toMemberId == b.toMemberId &&
      a.amount == b.amount &&
      a.currency == b.currency;

  String _readableMessage(Exception e) {
    final s = e.toString();
    const prefix = 'Exception: ';
    return s.startsWith(prefix) ? s.substring(prefix.length) : s;
  }
}
