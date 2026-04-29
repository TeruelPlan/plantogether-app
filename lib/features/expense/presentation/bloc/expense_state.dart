import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entity/expense.dart';
import '../../domain/entity/expense_submit_error.dart';

part 'expense_state.freezed.dart';

@freezed
sealed class ExpenseState with _$ExpenseState {
  const factory ExpenseState.initial() = _Initial;
  const factory ExpenseState.loading() = _Loading;
  const factory ExpenseState.loaded({
    required List<Expense> expenses,
    required int totalElements,
    required int currentPage,
    required bool hasMore,
  }) = _Loaded;
  const factory ExpenseState.error({required String message}) = _Error;

  /// Submit-time failure (Story 5.2 AC-5). The form keeps its state so the
  /// user does not lose their input; the page falls back to the last known
  /// list (carried for re-rendering convenience).
  const factory ExpenseState.submitFailed({
    required ExpenseSubmitError error,
    required List<Expense> expenses,
    required int totalElements,
    required int currentPage,
    required bool hasMore,
  }) = _SubmitFailed;
}
