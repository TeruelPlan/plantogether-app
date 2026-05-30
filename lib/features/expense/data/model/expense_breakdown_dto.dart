import 'package:json_annotation/json_annotation.dart';

import '../../domain/entity/expense.dart';
import '../../domain/entity/expense_breakdown.dart';

part 'expense_breakdown_dto.g.dart';

@JsonSerializable()
class CategoryBreakdownEntryDto {
  final String category;
  final double totalAmount;
  final double percentage;
  final int expenseCount;

  const CategoryBreakdownEntryDto({
    required this.category,
    required this.totalAmount,
    required this.percentage,
    required this.expenseCount,
  });

  factory CategoryBreakdownEntryDto.fromJson(Map<String, dynamic> json) =>
      _$CategoryBreakdownEntryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryBreakdownEntryDtoToJson(this);

  CategoryBreakdownEntry toDomain() => CategoryBreakdownEntry(
        category: ExpenseCategory.fromWire(category),
        totalAmount: totalAmount,
        percentage: percentage,
        expenseCount: expenseCount,
      );
}

@JsonSerializable()
class ExpenseBreakdownDto {
  final String tripId;
  final String referenceCurrency;
  final double totalAmount;
  final List<CategoryBreakdownEntryDto> categories;
  final DateTime? computedAt;

  const ExpenseBreakdownDto({
    required this.tripId,
    required this.referenceCurrency,
    required this.totalAmount,
    required this.categories,
    this.computedAt,
  });

  factory ExpenseBreakdownDto.fromJson(Map<String, dynamic> json) =>
      _$ExpenseBreakdownDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ExpenseBreakdownDtoToJson(this);

  ExpenseBreakdown toDomain() => ExpenseBreakdown(
        tripId: tripId,
        referenceCurrency: referenceCurrency,
        totalAmount: totalAmount,
        categories: categories.map((c) => c.toDomain()).toList(),
        computedAt: computedAt,
      );
}
