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
      final updated =
          await _repository.updateExpense(event.expenseId, event.input);
      // In-place update against whatever the current state is — avoids racing
      // with a STOMP-triggered LoadExpenses that may have just landed.
      final current = _extractList(state);
      final replaced = [
        for (final e in current.$1) e.id == updated.id ? updated : e,
      ];
      // If the expense vanished from the list (deleted elsewhere), keep the
      // server result by appending — the next reload will sort it.
      final hadIt = current.$1.any((e) => e.id == updated.id);
      final nextExpenses = hadIt ? replaced : [...current.$1, updated];
      emit(ExpenseState.updateCompleted(
        expenseId: updated.id,
        expenses: nextExpenses,
        totalElements:
            hadIt ? current.$2 : (current.$2 == 0 ? 1 : current.$2 + 1),
        currentPage: current.$3,
        hasMore: current.$4,
      ));
      // Settle back to the canonical loaded state for the page-level builder.
      emit(ExpenseState.loaded(
        expenses: nextExpenses,
        totalElements:
            hadIt ? current.$2 : (current.$2 == 0 ? 1 : current.$2 + 1),
        currentPage: current.$3,
        hasMore: current.$4,
      ));
    } on ExpenseSubmitError catch (e) {
      final fallback = _extractList(previous);
      emit(ExpenseState.submitFailed(
        error: e,
        expenses: fallback.$1,
        totalElements: fallback.$2,
        currentPage: fallback.$3,
        hasMore: fallback.$4,
      ));
      // 403/404: the entry is now stale — drop it from the local list rather
      // than re-fetching (which races with concurrent reloads).
      if (e.statusCode == 403 || e.statusCode == 404) {
        final pruned = fallback.$1
            .where((expense) => expense.id != event.expenseId)
            .toList();
        emit(ExpenseState.loaded(
          expenses: pruned,
          totalElements:
              fallback.$2 > pruned.length ? pruned.length : fallback.$2,
          currentPage: fallback.$3,
          hasMore: fallback.$4,
        ));
      }
    } on Exception catch (e) {
      emit(ExpenseState.error(message: _readableMessage(e)));
    }
  }

  Future<void> _onDelete(
      DeleteExpense event, Emitter<ExpenseState> emit) async {
    final snapshot = _extractList(state);
    final removed =
        snapshot.$1.where((e) => e.id == event.expenseId).firstOrNull;
    if (removed == null) return;

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
      // Already optimistically removed; do not dispatch a reload (would race
      // with concurrent LoadExpenses).
    } on ExpenseSubmitError catch (e) {
      if (e.statusCode == 404) {
        // Already gone server-side — keep the optimistic state.
        return;
      }
      // Roll back ONLY if the expense isn't already absent from the current
      // (possibly fresher) state. Diff against `state` instead of replaying
      // the snapshot — otherwise a concurrent reload that landed between the
      // optimistic emit and this rollback would be overwritten.
      final current = _extractList(state);
      final alreadyAbsent =
          !current.$1.any((expense) => expense.id == event.expenseId);
      final restoredExpenses = alreadyAbsent
          ? [...current.$1, removed]
          : current.$1;
      emit(ExpenseState.submitFailed(
        error: e,
        expenses: restoredExpenses,
        totalElements: alreadyAbsent ? current.$2 + 1 : current.$2,
        currentPage: current.$3,
        hasMore: current.$4,
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
      updateCompleted: (_, expenses, totalElements, currentPage, hasMore) =>
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
