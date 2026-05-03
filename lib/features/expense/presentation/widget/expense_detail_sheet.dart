import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entity/expense.dart';

/// Bottom-sheet showing the full FX breakdown for an expense (AC-6).
///
/// Edit/delete are deferred to Story 5.3.
class ExpenseDetailSheet extends StatelessWidget {
  final Expense expense;
  final String payerDisplayName;

  const ExpenseDetailSheet({
    super.key,
    required this.expense,
    required this.payerDisplayName,
  });

  static Future<void> show(
    BuildContext context, {
    required Expense expense,
    required String payerDisplayName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ExpenseDetailSheet(
        expense: expense,
        payerDisplayName: payerDisplayName,
      ),
    );
  }

  String _formatAmount(double amount, String currency) {
    final fmt = NumberFormat.currency(
      locale: 'en_US',
      name: currency,
      symbol: '$currency ',
      decimalDigits: 2,
    );
    return fmt.format(amount).trim();
  }

  String _formatRate(double rate) => rate.toStringAsFixed(4);

  String _formatRateFetchedAt(DateTime when) {
    final utc = when.toUtc();
    return '${DateFormat('yyyy-MM-dd HH:mm', 'en_US').format(utc)} UTC';
  }

  String _rateSourceLabel(RateSource source) {
    switch (source) {
      case RateSource.live:
        return 'Live';
      case RateSource.cached:
        return 'Cached';
      case RateSource.fallback:
        return 'Cached fallback';
    }
  }

  String _categoryLabel(ExpenseCategory category) =>
      category.name[0].toUpperCase() + category.name.substring(1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCrossCurrency = expense.referenceCurrency != null &&
        expense.currency != expense.referenceCurrency;

    return Padding(
      key: const ValueKey('expense_detail_sheet'),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            expense.description,
            key: const ValueKey('expense_detail_description'),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Paid by $payerDisplayName',
            key: const ValueKey('expense_detail_payer'),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Category: ${_categoryLabel(expense.category)}',
            key: const ValueKey('expense_detail_category'),
            style: theme.textTheme.bodyMedium,
          ),
          const Divider(height: 24),
          _row(
            theme,
            keyName: 'expense_detail_amount',
            label: 'Amount',
            value: _formatAmount(expense.amount, expense.currency),
          ),
          if (isCrossCurrency) ...[
            const SizedBox(height: 8),
            _row(
              theme,
              keyName: 'expense_detail_converted',
              label: 'Converted',
              value: _formatAmount(
                expense.amountInReferenceCurrency ?? expense.amount,
                expense.referenceCurrency!,
              ),
            ),
            const SizedBox(height: 8),
            _row(
              theme,
              keyName: 'expense_detail_rate',
              label: 'Exchange rate',
              value:
                  '1 ${expense.currency} = ${_formatRate(expense.exchangeRate)} ${expense.referenceCurrency}',
            ),
            const SizedBox(height: 8),
            _row(
              theme,
              keyName: 'expense_detail_rate_source',
              label: 'Rate source',
              value: _rateSourceLabel(expense.rateSource),
            ),
            if (expense.rateFetchedAt != null) ...[
              const SizedBox(height: 8),
              _row(
                theme,
                keyName: 'expense_detail_rate_fetched_at',
                label: 'Rate fetched at',
                value: _formatRateFetchedAt(expense.rateFetchedAt!),
              ),
            ],
          ],
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const ValueKey('expense_detail_close_button'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    ThemeData theme, {
    required String keyName,
    required String label,
    required String value,
  }) {
    return Row(
      key: ValueKey(keyName),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
