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
    on<UpdateExpense>(_onUpdate, transformer: droppable());
    on<DeleteExpense>(_onDelete, transformer: droppable());
  }

  Future<void> _onUpdate(
      UpdateExpense event, Emitter<ExpenseState> emit) async {
    final previous = state;
    try {
      await _repository.updateExpense(event.expenseId, event.input);
      add(LoadExpenses(event.tripId));
    } on ExpenseSubmitError catch (e) {
      // Keep the form's data intact: surface the error AND refresh the list
      // so a remote 403/404 cleans up stale entries (AC 10).
      final fallback = _extractList(previous);
      emit(ExpenseState.submitFailed(
        error: e,
        expenses: fallback.$1,
        totalElements: fallback.$2,
        currentPage: fallback.$3,
        hasMore: fallback.$4,
      ));
      if (e.statusCode == 403 || e.statusCode == 404) {
        add(LoadExpenses(event.tripId));
      }
    } on Exception catch (e) {
      emit(ExpenseState.error(message: _readableMessage(e)));
    }
  }

  Future<void> _onDelete(
      DeleteExpense event, Emitter<ExpenseState> emit) async {
    final previous = state;
    final snapshot = _extractList(previous);
    final optimistic =
        snapshot.$1.where((e) => e.id != event.expenseId).toList();
    emit(ExpenseState.loaded(
      expenses: optimistic,
      totalElements: snapshot.$2 > 0 ? snapshot.$2 - 1 : 0,
      currentPage: snapshot.$3,
      hasMore: snapshot.$4,
    ));
    try {
      await _repository.deleteExpense(event.expenseId);
      // Re-sync from the server (also covers 204 + STOMP-triggered remote deletes).
      add(LoadExpenses(event.tripId));
    } on ExpenseSubmitError catch (e) {
      if (e.statusCode == 404) {
        // Already gone — keep the optimistic state.
        add(LoadExpenses(event.tripId));
        return;
      }
      // Roll back: re-emit the prior list and surface the error.
      emit(ExpenseState.submitFailed(
        error: e,
        expenses: snapshot.$1,
        totalElements: snapshot.$2,
        currentPage: snapshot.$3,
        hasMore: snapshot.$4,
      ));
    } on Exception catch (e) {
      emit(ExpenseState.error(message: _readableMessage(e)));
    }
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
