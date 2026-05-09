import 'package:equatable/equatable.dart';

import '../../domain/repository/expense_repository.dart';

abstract class ExpenseEvent extends Equatable {
  const ExpenseEvent();

  @override
  List<Object?> get props => [];
}

class LoadExpenses extends ExpenseEvent {
  final String tripId;

  const LoadExpenses(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

class RecordExpense extends ExpenseEvent {
  final String tripId;
  final RecordExpenseInput input;

  const RecordExpense({required this.tripId, required this.input});

  @override
  List<Object?> get props => [tripId, input];
}

class UpdateExpense extends ExpenseEvent {
  final String tripId;
  final String expenseId;
  final UpdateExpenseInput input;

  const UpdateExpense({
    required this.tripId,
    required this.expenseId,
    required this.input,
  });

  @override
  List<Object?> get props => [tripId, expenseId, input];
}

class DeleteExpense extends ExpenseEvent {
  final String tripId;
  final String expenseId;

  const DeleteExpense({required this.tripId, required this.expenseId});

  @override
  List<Object?> get props => [tripId, expenseId];
}
