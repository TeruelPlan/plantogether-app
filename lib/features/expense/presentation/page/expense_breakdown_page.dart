import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/breakdown/expense_breakdown_bloc.dart';
import '../bloc/breakdown/expense_breakdown_event.dart';
import '../bloc/breakdown/expense_breakdown_state.dart';
import '../widget/category_breakdown_tile.dart';
import '../widget/expense_breakdown_chart.dart';

/// Full-screen per-category spend breakdown (story 5.5).
class ExpenseBreakdownPage extends StatefulWidget {
  final String tripId;

  const ExpenseBreakdownPage({super.key, required this.tripId});

  @override
  State<ExpenseBreakdownPage> createState() => _ExpenseBreakdownPageState();
}

class _ExpenseBreakdownPageState extends State<ExpenseBreakdownPage> {
  @override
  void initState() {
    super.initState();
    final bloc = context.read<ExpenseBreakdownBloc>();
    bloc.state.maybeWhen(
      initial: () => bloc.add(LoadBreakdown(widget.tripId)),
      orElse: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        key: const ValueKey('expense_breakdown_app_bar'),
        title: const Text('Breakdown'),
      ),
      body: BlocBuilder<ExpenseBreakdownBloc, ExpenseBreakdownState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(
              child: CircularProgressIndicator(
                key: ValueKey('expense_breakdown_loading'),
              ),
            ),
            empty: () => _emptyState(context),
            error: (message) => _errorState(context, message),
            loaded: (breakdown) => RefreshIndicator(
              onRefresh: () async {
                context
                    .read<ExpenseBreakdownBloc>()
                    .add(RefreshBreakdown(widget.tripId));
              },
              child: ListView(
                key: const ValueKey('expense_breakdown_list'),
                children: [
                  const SizedBox(height: 16),
                  ExpenseBreakdownChart(entries: breakdown.categories),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Total spent — '
                      '${NumberFormat.currency(name: breakdown.referenceCurrency, symbol: breakdown.referenceCurrency).format(breakdown.totalAmount)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final entry in breakdown.categories)
                    CategoryBreakdownTile(
                      entry: entry,
                      currency: breakdown.referenceCurrency,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      key: const ValueKey('expense_breakdown_empty_state'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.pie_chart_outline, size: 64),
          const SizedBox(height: 16),
          const Text('No spending yet'),
          const SizedBox(height: 4),
          const Text('Add the first expense'),
          const SizedBox(height: 16),
          TextButton(
            key: const ValueKey('expense_breakdown_empty_cta'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to expenses'),
          ),
        ],
      ),
    );
  }

  Widget _errorState(BuildContext context, String message) {
    return Center(
      key: const ValueKey('expense_breakdown_error'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 12),
          ElevatedButton(
            key: const ValueKey('expense_breakdown_retry_button'),
            onPressed: () => context
                .read<ExpenseBreakdownBloc>()
                .add(LoadBreakdown(widget.tripId)),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
