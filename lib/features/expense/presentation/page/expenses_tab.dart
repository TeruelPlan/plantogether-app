import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../trip/domain/model/trip_model.dart';
import '../bloc/expense_bloc.dart';
import '../bloc/expense_event.dart';
import '../bloc/expense_state.dart';
import '../widget/add_expense_sheet.dart';
import '../widget/expense_card.dart';

class ExpensesTab extends StatefulWidget {
  final String tripId;
  final TripModel trip;

  const ExpensesTab({
    super.key,
    required this.tripId,
    required this.trip,
  });

  @override
  State<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<ExpensesTab> {
  bool _fabPressed = false;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<ExpenseBloc>();
    bloc.state.maybeWhen(
      initial: () => bloc.add(LoadExpenses(widget.tripId)),
      orElse: () {},
    );
  }

  String _resolveDisplayName(String deviceId) {
    final member = widget.trip.members
        .where((m) => m.memberId == deviceId)
        .firstOrNull;
    return member?.displayName ?? 'Unknown';
  }

  void _openAddSheet() {
    if (_fabPressed) return;
    _fabPressed = true;
    showAddExpenseSheet(
      context,
      tripId: widget.tripId,
      trip: widget.trip,
    ).whenComplete(() {
      if (mounted) {
        setState(() => _fabPressed = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (context, state) {
        return state.when(
          initial: () => const Center(child: CircularProgressIndicator()),
          loading: () => const Center(
            child: CircularProgressIndicator(
              key: ValueKey('expenses_loading'),
            ),
          ),
          loaded: (expenses, totalElements, currentPage, hasMore) {
            if (expenses.isEmpty) {
              return _buildEmptyState();
            }
            return _buildLoadedState(expenses);
          },
          submitFailed: (_, expenses, __, ___, ____) {
            if (expenses.isEmpty) {
              return _buildEmptyState();
            }
            return _buildLoadedState(expenses);
          },
          error: (message) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message),
                const SizedBox(height: 12),
                ElevatedButton(
                  key: const ValueKey('expenses_retry_button'),
                  onPressed: () =>
                      context.read<ExpenseBloc>().add(LoadExpenses(widget.tripId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        key: const ValueKey('expenses_empty_state'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 64),
          const SizedBox(height: 16),
          const Text('No expenses yet · Add the first expense'),
          const SizedBox(height: 24),
          FloatingActionButton.extended(
            key: const ValueKey('expenses_add_fab'),
            heroTag: 'expenses_fab',
            tooltip: 'Add expense',
            onPressed: _openAddSheet,
            icon: const Icon(Icons.add),
            label: const Text('Add expense'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedState(List expenses) {
    return Scaffold(
      body: ListView.builder(
        key: const ValueKey('expenses_list'),
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          final expense = expenses[index];
          return ExpenseCard(
            expense: expense,
            payerDisplayName: _resolveDisplayName(expense.paidByDeviceId),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('expenses_add_fab'),
        heroTag: 'expenses_fab',
        tooltip: 'Add expense',
        onPressed: _openAddSheet,
        child: const Icon(Icons.add),
      ),
    );
  }
}
