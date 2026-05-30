import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/expense_category_tokens.dart';
import '../../domain/entity/expense_breakdown.dart';

/// One row of the breakdown list: colour dot, category label, expense count,
/// amount and percentage (story 5.5).
class CategoryBreakdownTile extends StatelessWidget {
  final CategoryBreakdownEntry entry;
  final String currency;

  const CategoryBreakdownTile({
    super.key,
    required this.entry,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = NumberFormat.currency(name: currency, symbol: currency)
        .format(entry.totalAmount);
    final percentLabel = entry.percentage < 1
        ? '<1%'
        : '${entry.percentage.toStringAsFixed(1)}%';

    return ListTile(
      key: ValueKey('category_breakdown_tile_${entry.category.name}'),
      leading: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: expenseCategoryColors[entry.category],
        ),
      ),
      title: Text(expenseCategoryLabel(entry.category)),
      subtitle: Text(
        '${entry.expenseCount} expense${entry.expenseCount == 1 ? '' : 's'}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(amount, style: theme.textTheme.titleMedium),
          Text(percentLabel, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
