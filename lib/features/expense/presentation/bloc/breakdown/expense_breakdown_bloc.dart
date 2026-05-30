import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repository/expense_repository.dart';
import 'expense_breakdown_event.dart';
import 'expense_breakdown_state.dart';

class ExpenseBreakdownBloc
    extends Bloc<ExpenseBreakdownEvent, ExpenseBreakdownState> {
  final ExpenseRepository _repository;

  ExpenseBreakdownBloc(this._repository)
      : super(const ExpenseBreakdownState.initial()) {
    on<LoadBreakdown>(_onLoad, transformer: droppable());
    on<RefreshBreakdown>(_onRefresh, transformer: droppable());
  }

  Future<void> _onLoad(
    LoadBreakdown event,
    Emitter<ExpenseBreakdownState> emit,
  ) async {
    emit(const ExpenseBreakdownState.loading());
    await _fetch(event.tripId, emit);
  }

  Future<void> _onRefresh(
    RefreshBreakdown event,
    Emitter<ExpenseBreakdownState> emit,
  ) async {
    await _fetch(event.tripId, emit);
  }

  Future<void> _fetch(
    String tripId,
    Emitter<ExpenseBreakdownState> emit,
  ) async {
    try {
      final breakdown = await _repository.getBreakdown(tripId);
      if (emit.isDone) return;
      if (breakdown.categories.isEmpty) {
        emit(const ExpenseBreakdownState.empty());
      } else {
        emit(ExpenseBreakdownState.loaded(breakdown: breakdown));
      }
    } on Exception catch (e) {
      if (emit.isDone) return;
      emit(ExpenseBreakdownState.error(message: _readableMessage(e)));
    }
  }

  String _readableMessage(Exception e) {
    final s = e.toString();
    const prefix = 'Exception: ';
    return s.startsWith(prefix) ? s.substring(prefix.length) : s;
  }
}
