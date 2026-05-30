import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/entity/expense_breakdown.dart';

part 'expense_breakdown_state.freezed.dart';

@freezed
sealed class ExpenseBreakdownState with _$ExpenseBreakdownState {
  const factory ExpenseBreakdownState.initial() = _Initial;
  const factory ExpenseBreakdownState.loading() = _Loading;
  const factory ExpenseBreakdownState.loaded({
    required ExpenseBreakdown breakdown,
  }) = _Loaded;

  /// Distinct from [loaded] so the UI can route to the empty-state widget
  /// (no pie chart) per AC 3.
  const factory ExpenseBreakdownState.empty() = _Empty;
  const factory ExpenseBreakdownState.error({required String message}) = _Error;
}
