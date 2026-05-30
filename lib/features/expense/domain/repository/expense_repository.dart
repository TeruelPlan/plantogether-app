import '../entity/expense.dart';
import '../entity/expense_breakdown.dart';

abstract class ExpenseRepository {
  Future<Expense> record(String tripId, RecordExpenseInput input);
  Future<ExpensePage> list(String tripId, {int page = 0, int size = 20});
  Future<Expense> updateExpense(String expenseId, UpdateExpenseInput input);
  Future<void> deleteExpense(String expenseId);
  Future<ExpenseBreakdown> getBreakdown(String tripId);
}

class UpdateExpenseInput {
  final double amount;
  final String currency;
  final ExpenseCategory category;
  final String description;
  final String? receiptKey;
  final SplitMode splitMode;
  final List<ExpenseSplit>? splits;

  const UpdateExpenseInput({
    required this.amount,
    required this.currency,
    required this.category,
    required this.description,
    this.receiptKey,
    this.splitMode = SplitMode.equal,
    this.splits,
  });
}

class ExpensePage {
  final List<Expense> expenses;
  final int totalElements;
  final int totalPages;
  final int currentPage;
  final int size;

  const ExpensePage({
    required this.expenses,
    required this.totalElements,
    required this.totalPages,
    required this.currentPage,
    required this.size,
  });

  bool get hasMore => currentPage + 1 < totalPages;
}

class RecordExpenseInput {
  final double amount;
  final String currency;
  final ExpenseCategory category;
  final String description;
  final SplitMode splitMode;
  final List<ExpenseSplit>? splits;
  final String? paidByMemberId;

  const RecordExpenseInput({
    required this.amount,
    required this.currency,
    required this.category,
    required this.description,
    this.splitMode = SplitMode.equal,
    this.splits,
    this.paidByMemberId,
  });
}
