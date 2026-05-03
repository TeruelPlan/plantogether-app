import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entity/expense.dart';
import '../../domain/entity/expense_submit_error.dart';
import '../../domain/repository/expense_repository.dart'
    show ExpenseRepository;
import 'expense_event.dart';
import 'expense_state.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final ExpenseRepository _repository;

  ExpenseBloc(this._repository) : super(const ExpenseState.initial()) {
    on<LoadExpenses>(_onLoad, transformer: droppable());
    on<RecordExpense>(_onRecord, transformer: droppable());
  }

  Future<void> _onLoad(LoadExpenses event, Emitter<ExpenseState> emit) async {
    emit(const ExpenseState.loading());
    try {
      final page = await _repository.list(event.tripId);
      emit(ExpenseState.loaded(
        expenses: page.expenses,
        totalElements: page.totalElements,
        currentPage: page.currentPage,
        hasMore: page.hasMore,
      ));
    } on Exception catch (e) {
      emit(ExpenseState.error(message: _readableMessage(e)));
    }
  }

  Future<void> _onRecord(
      RecordExpense event, Emitter<ExpenseState> emit) async {
    // Snapshot the previous loaded list so a submit failure can fall back.
    final previous = state;
    emit(const ExpenseState.loading());
    try {
      await _repository.record(event.tripId, event.input);
      add(LoadExpenses(event.tripId));
    } on ExpenseSubmitError catch (e) {
      // AC-5: surface the error to the form WITHOUT losing user input.
      // Restore the prior list (if any) so the page below the sheet
      // continues to render.
      final fallback = _extractList(previous);
      emit(ExpenseState.submitFailed(
        error: e,
        expenses: fallback.$1,
        totalElements: fallback.$2,
        currentPage: fallback.$3,
        hasMore: fallback.$4,
      ));
    } on Exception catch (e) {
      emit(ExpenseState.error(message: _readableMessage(e)));
    }
  }

  (List<Expense>, int, int, bool) _extractList(ExpenseState s) {
    return s.maybeWhen(
      loaded: (expenses, totalElements, currentPage, hasMore) =>
          (expenses, totalElements, currentPage, hasMore),
      submitFailed: (_, expenses, totalElements, currentPage, hasMore) =>
          (expenses, totalElements, currentPage, hasMore),
      orElse: () => (const <Expense>[], 0, 0, false),
    );
  }

  String _readableMessage(Exception e) {
    final s = e.toString();
    const prefix = 'Exception: ';
    return s.startsWith(prefix) ? s.substring(prefix.length) : s;
  }
}
