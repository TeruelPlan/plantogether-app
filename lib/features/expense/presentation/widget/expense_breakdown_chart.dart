import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/expense_category_tokens.dart';
import '../../domain/entity/expense_breakdown.dart';

/// Pie chart of category spend (story 5.5). Never call this with an empty
/// [entries] list — the page guards the empty state before reaching here.
class ExpenseBreakdownChart extends StatelessWidget {
  final List<CategoryBreakdownEntry> entries;

  const ExpenseBreakdownChart({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final single = entries.length == 1;
    return SizedBox(
      key: const ValueKey('expense_breakdown_chart'),
      height: 260,
      child: PieChart(
        PieChartData(
          sectionsSpace: single ? 0 : 2,
          centerSpaceRadius: 48,
          startDegreeOffset: -90,
          sections: [
            for (final e in entries)
              PieChartSectionData(
                value: e.totalAmount,
                color: expenseCategoryColors[e.category],
                title: '${e.percentage.toStringAsFixed(0)}%',
                radius: 72,
                titleStyle: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
