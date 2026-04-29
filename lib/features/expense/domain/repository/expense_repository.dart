import '../entity/expense.dart';

abstract class ExpenseRepository {
  Future<Expense> record(String tripId, RecordExpenseInput input);
  Future<ExpensePage> list(String tripId, {int page = 0, int size = 20});
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
  final String? paidByDeviceId;

  const RecordExpenseInput({
    required this.amount,
    required this.currency,
    required this.category,
    required this.description,
    this.splitMode = SplitMode.equal,
    this.splits,
    this.paidByDeviceId,
  });
}
