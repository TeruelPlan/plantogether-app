import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entity/expense.dart';
import 'expense_detail_sheet.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final String payerDisplayName;

  const ExpenseCard({
    super.key,
    required this.expense,
    required this.payerDisplayName,
  });

  String _relativeDate(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${local.day}/${local.month}/${local.year}';
  }

  String _categoryLabel(ExpenseCategory category) {
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

  static const _currencySymbols = {
    'EUR': '€',
    'USD': r'$',
    'GBP': '£',
    'CHF': 'CHF',
    'JPY': '¥',
  };

  String _formatAmount(double amount, String currency) {
    final symbol = _currencySymbols[currency] ?? currency;
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountText = _formatAmount(expense.amount, expense.currency);
    final isCrossCurrency = expense.referenceCurrency != null &&
        expense.currency != expense.referenceCurrency;
    final showFallbackChip = expense.rateSource == RateSource.fallback;

    return Card(
      key: ValueKey('expense_card_${expense.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () => ExpenseDetailSheet.show(
          context,
          expense: expense,
          payerDisplayName: payerDisplayName,
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              payerDisplayName.isNotEmpty
                  ? payerDisplayName[0].toUpperCase()
                  : '?',
              style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
            ),
          ),
          title: Text(
            '$payerDisplayName paid $amountText',
            key: ValueKey('expense_card_amount_${expense.id}'),
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isCrossCurrency)
                Text(
                  '≈ ${_formatAmount(expense.amountInReferenceCurrency ?? expense.amount, expense.referenceCurrency!)}',
                  key: ValueKey('expense_card_converted_${expense.id}'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              if (showFallbackChip)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _FallbackChip(
                    key: ValueKey(
                        'expense_card_fallback_chip_${expense.id}'),
                    rateFetchedAt: expense.rateFetchedAt,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                expense.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Chip(
                label: Text(_categoryLabel(expense.category)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          trailing: Text(
            _relativeDate(expense.createdAt),
            style: theme.textTheme.bodySmall,
          ),
          isThreeLine: true,
        ),
      ),
    );
  }
}

class _FallbackChip extends StatelessWidget {
  final DateTime? rateFetchedAt;

  const _FallbackChip({super.key, required this.rateFetchedAt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = rateFetchedAt != null
        ? 'Using cached rate from ${DateFormat('yyyy-MM-dd', 'en_US').format(rateFetchedAt!.toUtc())}'
        : 'Using cached rate (date unknown)';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 14, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onErrorContainer),
          ),
        ],
      ),
    );
  }
}
