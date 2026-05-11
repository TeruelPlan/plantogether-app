import 'package:dio/dio.dart';

import '../../domain/entity/expense.dart';
import '../../domain/entity/expense_submit_error.dart';
import '../../domain/repository/expense_repository.dart';
import '../datasource/expense_remote_datasource.dart';
import '../model/expense_dto.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDatasource _remoteDatasource;

  ExpenseRepositoryImpl(this._remoteDatasource);

  @override
  Future<Expense> record(String tripId, RecordExpenseInput input) async {
    try {
      final body = RecordExpenseRequestDto(
        amount: input.amount,
        currency: input.currency,
        category: input.category.toWire(),
        description: input.description,
        splitMode: input.splitMode.toWire(),
        splits: input.splits
            ?.map((s) => SplitInputDto(
                  memberId: s.memberId,
                  shareAmount: s.shareAmount,
                ))
            .toList(),
        paidByMemberId: input.paidByMemberId,
      );
      final dto = await _remoteDatasource.record(tripId, body);
      return dto.toDomain();
    } on DioException catch (e) {
      throw _mapSubmitError(e, input);
    }
  }

  @override
  Future<ExpensePage> list(String tripId,
      {int page = 0, int size = 20}) async {
    try {
      final dtoPage =
          await _remoteDatasource.list(tripId, page: page, size: size);
      return ExpensePage(
        expenses: dtoPage.content.map((d) => d.toDomain()).toList(),
        totalElements: dtoPage.totalElements,
        totalPages: dtoPage.totalPages,
        currentPage: dtoPage.number,
        size: dtoPage.size,
      );
    } on DioException catch (e) {
      throw _mapListError(e);
    }
  }

  @override
  Future<Expense> updateExpense(
      String expenseId, UpdateExpenseInput input) async {
    try {
      final body = UpdateExpenseRequestDto(
        amount: input.amount,
        currency: input.currency,
        category: input.category.toWire(),
        description: input.description,
        receiptKey: input.receiptKey,
        splitMode: input.splitMode.toWire(),
        splits: input.splits
            ?.map((s) => SplitInputDto(
                  memberId: s.memberId,
                  shareAmount: s.shareAmount,
                ))
            .toList(),
      );
      final dto = await _remoteDatasource.update(expenseId, body);
      return dto.toDomain();
    } on DioException catch (e) {
      throw _mapModificationError(e, fallback: 'Failed to update expense');
    }
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    try {
      await _remoteDatasource.delete(expenseId);
    } on DioException catch (e) {
      throw _mapModificationError(e, fallback: 'Failed to delete expense');
    }
  }

  ExpenseSubmitError _mapModificationError(DioException e,
      {required String fallback}) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    String? detail;
    if (data is Map<String, dynamic>) {
      detail = data['detail'] as String?;
    }
    if (statusCode == 403) {
      return const ExpenseSubmitError(
        message: "You can't modify this expense anymore",
        statusCode: 403,
      );
    }
    if (statusCode == 404) {
      return const ExpenseSubmitError(
        message: 'This expense no longer exists',
        statusCode: 404,
      );
    }
    if (statusCode == 400) {
      return ExpenseSubmitError(
        message: detail ?? 'Invalid expense data. Please check your inputs',
        statusCode: 400,
      );
    }
    if (statusCode != null && statusCode >= 500) {
      return ExpenseSubmitError(
        message: detail ?? fallback,
        statusCode: statusCode,
      );
    }
    return const ExpenseSubmitError(
      message: 'Network error. Please check your connection',
    );
  }

  ExpenseSubmitError _mapSubmitError(
      DioException e, RecordExpenseInput input) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    String? title;
    String? detail;
    String? base;
    String? quote;
    if (data is Map<String, dynamic>) {
      title = data['title'] as String?;
      detail = data['detail'] as String?;
      base = data['baseCurrency'] as String?;
      quote = data['quoteCurrency'] as String?;
    }

    if (statusCode == 503) {
      return ExpenseSubmitError(
        message: detail ??
            'Exchange rate unavailable for ${base ?? input.currency} → '
                '${quote ?? "?"}. Try again or change currency.',
        statusCode: 503,
        isFxUnavailable: true,
        baseCurrency: base ?? input.currency,
        quoteCurrency: quote,
      );
    }
    if (statusCode == 403) {
      return const ExpenseSubmitError(
        message: 'You are not a member of this trip',
        statusCode: 403,
      );
    }
    if (statusCode == 400) {
      return ExpenseSubmitError(
        message: detail ?? 'Invalid expense data. Please check your inputs',
        statusCode: 400,
      );
    }
    if (statusCode != null && statusCode >= 500) {
      return ExpenseSubmitError(
        message: title ?? 'Server error. Please try again later',
        statusCode: statusCode,
      );
    }
    return const ExpenseSubmitError(
      message: 'Network error. Please check your connection',
    );
  }

  Exception _mapListError(DioException e) {
    final statusCode = e.response?.statusCode;
    if (statusCode == 403) {
      return Exception('You are not a member of this trip');
    }
    if (statusCode != null && statusCode >= 500) {
      return Exception('Server error. Please try again later');
    }
    return Exception('Network error. Please check your connection');
  }
}
