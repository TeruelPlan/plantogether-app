import 'package:flutter/material.dart';

import '../../features/expense/domain/entity/expense.dart';

/// Single source of truth for category -> colour. Used by the breakdown pie
/// chart and the category tiles. Do NOT hard-code these hex values elsewhere.
const Map<ExpenseCategory, Color> expenseCategoryColors = {
  ExpenseCategory.transport: Color(0xFF3B82F6), // blue
  ExpenseCategory.accommodation: Color(0xFF8B5CF6), // purple
  ExpenseCategory.food: Color(0xFFF59E0B), // amber
  ExpenseCategory.activity: Color(0xFF10B981), // emerald
  ExpenseCategory.other: Color(0xFF6B7280), // slate
};

/// English display label for a category (i18n deferred).
String expenseCategoryLabel(ExpenseCategory category) {
  switch (category) {
    case ExpenseCategory.transport:
      return 'Transport';
    case ExpenseCategory.accommodation:
      return 'Accommodation';
    case ExpenseCategory.food:
      return 'Food';
    case ExpenseCategory.activity:
      return 'Activity';
    case ExpenseCategory.other:
      return 'Other';
  }
}
