import 'package:json_annotation/json_annotation.dart';

import '../../domain/entity/expense.dart';

part 'expense_dto.g.dart';

@JsonSerializable()
class ExpenseSplitDto {
  final String deviceId;
  final double shareAmount;

  const ExpenseSplitDto({required this.deviceId, required this.shareAmount});

  factory ExpenseSplitDto.fromJson(Map<String, dynamic> json) =>
      _$ExpenseSplitDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ExpenseSplitDtoToJson(this);

  ExpenseSplit toDomain() =>
      ExpenseSplit(deviceId: deviceId, shareAmount: shareAmount);
}

@JsonSerializable()
class ExpenseDto {
  final String id;
  final String tripId;
  final String paidByDeviceId;
  final double amount;
  final String currency;
  final String category;
  final String description;
  final String? receiptKey;
  final String splitMode;
  final List<ExpenseSplitDto> splits;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Multi-currency FX fields (Story 5.2). Server always returns them.
  final double? exchangeRate;
  final double? amountInReferenceCurrency;
  final String? referenceCurrency;
  final String? rateSource;
  final DateTime? rateFetchedAt;

  const ExpenseDto({
    required this.id,
    required this.tripId,
    required this.paidByDeviceId,
    required this.amount,
    required this.currency,
    required this.category,
    required this.description,
    this.receiptKey,
    required this.splitMode,
    required this.splits,
    required this.createdAt,
    required this.updatedAt,
    this.exchangeRate,
    this.amountInReferenceCurrency,
    this.referenceCurrency,
    this.rateSource,
    this.rateFetchedAt,
  });

  factory ExpenseDto.fromJson(Map<String, dynamic> json) =>
      _$ExpenseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ExpenseDtoToJson(this);

  Expense toDomain() => Expense(
        id: id,
        tripId: tripId,
        paidByDeviceId: paidByDeviceId,
        amount: amount,
        currency: currency,
        category: ExpenseCategory.fromWire(category),
        description: description,
        receiptKey: receiptKey,
        splitMode: SplitMode.fromWire(splitMode),
        splits: splits.map((s) => s.toDomain()).toList(),
        createdAt: createdAt,
        updatedAt: updatedAt,
        exchangeRate: exchangeRate ?? 1.0,
        amountInReferenceCurrency: amountInReferenceCurrency,
        referenceCurrency: referenceCurrency,
        rateSource: rateSource != null
            ? RateSource.fromString(rateSource!)
            : RateSource.live,
        rateFetchedAt: rateFetchedAt,
      );
}

@JsonSerializable(includeIfNull: false)
class RecordExpenseRequestDto {
  final double amount;
  final String currency;
  final String category;
  final String description;
  final String? receiptKey;
  final String splitMode;
  final List<SplitInputDto>? splits;
  final String? paidBy;

  const RecordExpenseRequestDto({
    required this.amount,
    required this.currency,
    required this.category,
    required this.description,
    this.receiptKey,
    required this.splitMode,
    this.splits,
    this.paidBy,
  });

  factory RecordExpenseRequestDto.fromJson(Map<String, dynamic> json) =>
      _$RecordExpenseRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RecordExpenseRequestDtoToJson(this);
}

@JsonSerializable()
class SplitInputDto {
  final String deviceId;
  final double shareAmount;

  const SplitInputDto({required this.deviceId, required this.shareAmount});

  factory SplitInputDto.fromJson(Map<String, dynamic> json) =>
      _$SplitInputDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SplitInputDtoToJson(this);
}
