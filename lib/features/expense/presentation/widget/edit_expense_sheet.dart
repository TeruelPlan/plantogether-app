import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/currencies.dart';
import '../../../trip/domain/model/trip_model.dart';
import '../../domain/entity/expense.dart';
import '../../domain/repository/expense_repository.dart';
import '../bloc/expense_bloc.dart';
import '../bloc/expense_event.dart';
import '../bloc/expense_state.dart';
import 'currency_selector.dart';

/// Story 5.3 — modal sheet to edit an existing expense. Pre-fills fields from
/// the given expense; submit dispatches an [UpdateExpense] event. Mirrors the
/// add sheet's hardening (gated `_submitted` flag, mounted guard, dedicated
/// "this submit" listener so a background reload won't pop the sheet).
Future<void> showEditExpenseSheet(
  BuildContext context, {
  required String tripId,
  required TripModel trip,
  required Expense expense,
}) {
  final bloc = context.read<ExpenseBloc>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: _EditExpenseSheet(tripId: tripId, trip: trip, expense: expense),
    ),
  );
}

class _EditExpenseSheet extends StatefulWidget {
  final String tripId;
  final TripModel trip;
  final Expense expense;

  const _EditExpenseSheet({
    required this.tripId,
    required this.trip,
    required this.expense,
  });

  @override
  State<_EditExpenseSheet> createState() => _EditExpenseSheetState();
}

class _EditExpenseSheetState extends State<_EditExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;

  late ExpenseCategory _category;
  late String _currency;
  String? _submitErrorMessage;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.expense.amount.toString());
    _descriptionController =
        TextEditingController(text: widget.expense.description);
    _category = widget.expense.category;
    _currency = widget.expense.currency;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  static double? _parseAmount(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  void _submit() {
    if (_submitted) return;
    if (!_formKey.currentState!.validate()) return;

    final amount = _parseAmount(_amountController.text);
    if (amount == null || amount <= 0) return;

    setState(() {
      _submitErrorMessage = null;
      _submitted = true;
    });

    context.read<ExpenseBloc>().add(UpdateExpense(
          tripId: widget.tripId,
          expenseId: widget.expense.id,
          input: UpdateExpenseInput(
            amount: amount,
            currency: _currency,
            category: _category,
            description: _descriptionController.text.trim(),
            splitMode: widget.expense.splitMode,
            splits: widget.expense.splits,
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExpenseBloc, ExpenseState>(
      listenWhen: (_, current) {
        if (!_submitted) return false;
        return current.maybeWhen(
          loaded: (_, __, ___, ____) => true,
          loading: () => false,
          error: (_) => true,
          submitFailed: (_, __, ___, ____, _____) => true,
          orElse: () => false,
        );
      },
      listener: (context, state) {
        state.whenOrNull(
          loaded: (_, __, ___, ____) {
            if (!mounted) return;
            Navigator.of(context).pop();
          },
          error: (message) {
            if (!mounted) return;
            setState(() {
              _submitted = false;
              _submitErrorMessage = message;
            });
          },
          submitFailed: (error, _, __, ___, ____) {
            if (!mounted) return;
            setState(() {
              _submitted = false;
              _submitErrorMessage = error.message;
            });
          },
        );
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit expense',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('expense_edit_amount_field'),
                controller: _amountController,
                enabled: !_submitted,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Amount is required';
                  }
                  final parsed = _parseAmount(value);
                  if (parsed == null || parsed <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('expense_edit_description_field'),
                controller: _descriptionController,
                enabled: !_submitted,
                maxLength: 255,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CurrencySelector(
                value: _currency.isNotEmpty
                    ? _currency
                    : (widget.trip.referenceCurrency ??
                        SupportedCurrencies.all.first),
                enabled: !_submitted,
                onChanged: (v) => setState(() => _currency = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ExpenseCategory>(
                key: const ValueKey('expense_edit_category_dropdown'),
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: ExpenseCategory.values
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(
                              c.name[0].toUpperCase() + c.name.substring(1)),
                        ))
                    .toList(),
                onChanged: _submitted
                    ? null
                    : (v) {
                        if (v != null) setState(() => _category = v);
                      },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                key: const ValueKey('expense_edit_submit_button'),
                onPressed: _submitted ? null : _submit,
                child: _submitted
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save changes'),
              ),
              if (_submitErrorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _submitErrorMessage!,
                  key: const ValueKey('expense_edit_submit_error_text'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
