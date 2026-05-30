import 'package:freezed_annotation/freezed_annotation.dart';

import 'expense.dart';

part 'expense_breakdown.freezed.dart';

/// One category's slice of the trip spend (story 5.5).
@freezed
sealed class CategoryBreakdownEntry with _$CategoryBreakdownEntry {
  const factory CategoryBreakdownEntry({
    required ExpenseCategory category,
    required double totalAmount,
    required double percentage,
    required int expenseCount,
  }) = _CategoryBreakdownEntry;
}

/// Trip spend grouped by category, in the reference currency.
@freezed
sealed class ExpenseBreakdown with _$ExpenseBreakdown {
  const factory ExpenseBreakdown({
    required String tripId,
    required String referenceCurrency,
    required double totalAmount,
    required List<CategoryBreakdownEntry> categories,
    DateTime? computedAt,
  }) = _ExpenseBreakdown;
}
