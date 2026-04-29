import 'package:freezed_annotation/freezed_annotation.dart';

part 'expense.freezed.dart';

enum ExpenseCategory {
  transport,
  accommodation,
  food,
  activity,
  other;

  String toWire() => name.toUpperCase();

  static ExpenseCategory fromWire(String s) {
    switch (s.toUpperCase()) {
      case 'TRANSPORT':
        return ExpenseCategory.transport;
      case 'ACCOMMODATION':
        return ExpenseCategory.accommodation;
      case 'FOOD':
        return ExpenseCategory.food;
      case 'ACTIVITY':
        return ExpenseCategory.activity;
      case 'OTHER':
      default:
        return ExpenseCategory.other;
    }
  }
}

enum SplitMode {
  equal,
  custom,
  percentage;

  String toWire() => name.toUpperCase();

  static SplitMode fromWire(String s) {
    switch (s.toUpperCase()) {
      case 'EQUAL':
        return SplitMode.equal;
      case 'CUSTOM':
        return SplitMode.custom;
      case 'PERCENTAGE':
        return SplitMode.percentage;
      default:
        return SplitMode.equal;
    }
  }
}

/// Source of the FX rate snapshotted at expense creation time.
enum RateSource {
  live,
  cached,
  fallback;

  String toWire() => name.toUpperCase();

  static RateSource fromString(String s) {
    switch (s.toUpperCase()) {
      case 'LIVE':
        return RateSource.live;
      case 'CACHED':
        return RateSource.cached;
      case 'FALLBACK':
        return RateSource.fallback;
      default:
        return RateSource.live;
    }
  }
}

@freezed
sealed class ExpenseSplit with _$ExpenseSplit {
  const factory ExpenseSplit({
    required String deviceId,
    required double shareAmount,
  }) = _ExpenseSplit;
}

@freezed
sealed class Expense with _$Expense {
  const factory Expense({
    required String id,
    required String tripId,
    required String paidByDeviceId,
    required double amount,
    required String currency,
    required ExpenseCategory category,
    required String description,
    String? receiptKey,
    required SplitMode splitMode,
    required List<ExpenseSplit> splits,
    required DateTime createdAt,
    required DateTime updatedAt,
    // Multi-currency FX snapshot (Story 5.2). Frozen at creation time.
    @Default(1.0) double exchangeRate,
    double? amountInReferenceCurrency,
    String? referenceCurrency,
    @Default(RateSource.live) RateSource rateSource,
    DateTime? rateFetchedAt,
  }) = _Expense;
}
