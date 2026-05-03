import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/security/device_id_service.dart';
import '../../../trip/domain/model/trip_model.dart';
import '../../domain/entity/expense.dart';
import '../../domain/repository/expense_repository.dart';
import '../bloc/expense_bloc.dart';
import '../bloc/expense_event.dart';
import '../bloc/expense_state.dart';
import '../../../../core/constants/currencies.dart';
import 'currency_selector.dart';

Future<void> showAddExpenseSheet(
  BuildContext context, {
  required String tripId,
  required TripModel trip,
}) {
  final bloc = context.read<ExpenseBloc>();
  final deviceIdService = context.read<DeviceIdService>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => RepositoryProvider.value(
      value: deviceIdService,
      child: BlocProvider.value(
        value: bloc,
        child: _AddExpenseSheet(tripId: tripId, trip: trip),
      ),
    ),
  );
}

class _AddExpenseSheet extends StatefulWidget {
  final String tripId;
  final TripModel trip;

  const _AddExpenseSheet({required this.tripId, required this.trip});

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  ExpenseCategory _category = ExpenseCategory.food;
  String? _payerDeviceId;
  String? _currency;
  String? _submitErrorMessage;
  bool _recordRequested = false;

  @override
  void initState() {
    super.initState();
    _currency = widget.trip.referenceCurrency;
    _initPayer();
  }

  Future<void> _initPayer() async {
    final deviceIdService = context.read<DeviceIdService>();
    final myId = await deviceIdService.getOrCreateDeviceId();
    if (mounted) {
      setState(() {
        _payerDeviceId = myId;
      });
    }
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
    if (!_formKey.currentState!.validate()) return;

    final amount = _parseAmount(_amountController.text);
    if (amount == null || amount <= 0) return;

    final selectedCurrency = _currency ?? widget.trip.referenceCurrency;
    if (selectedCurrency == null || selectedCurrency.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip currency is missing')),
      );
      return;
    }

    setState(() {
      _submitErrorMessage = null;
      _recordRequested = true;
    });

    context.read<ExpenseBloc>().add(RecordExpense(
          tripId: widget.tripId,
          input: RecordExpenseInput(
            amount: amount,
            currency: selectedCurrency,
            category: _category,
            description: _descriptionController.text.trim(),
            splitMode: SplitMode.equal,
            paidByDeviceId: _payerDeviceId,
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExpenseBloc, ExpenseState>(
      listenWhen: (previous, current) {
        if (!_recordRequested) return false;
        // React to any terminal state following a submit (loaded, error, submitFailed).
        // Using previous.isLoading would miss re-submit after submitFailed, so we check
        // whether current is a terminal state instead.
        return current.maybeWhen(
          loaded: (_, __, ___, ____) => true,
          error: (_) => true,
          submitFailed: (_, __, ___, ____, _____) => true,
          orElse: () => false,
        );
      },
      listener: (context, state) {
        state.whenOrNull(
          loaded: (_, __, ___, ____) {
            setState(() => _recordRequested = false);
            if (mounted) Navigator.of(context).pop();
          },
          error: (message) {
            setState(() => _recordRequested = false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            }
          },
          submitFailed: (error, _, __, ___, ____) {
            if (mounted) {
              // AC-5: keep form state intact; render inline error.
              setState(() {
                _recordRequested = false;
                _submitErrorMessage = error.message;
              });
            }
          },
        );
      },
      child: BlocBuilder<ExpenseBloc, ExpenseState>(
        builder: (context, state) {
          final isSubmitting = state.maybeWhen(
            loading: () => true,
            orElse: () => false,
          );
          return Padding(
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
                    'Add expense',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('expense_amount_field'),
                    controller: _amountController,
                    enabled: !isSubmitting,
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
                    key: const ValueKey('expense_description_field'),
                    controller: _descriptionController,
                    enabled: !isSubmitting,
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
                    value: _currency ??
                        widget.trip.referenceCurrency ??
                        SupportedCurrencies.all.first,
                    enabled: !isSubmitting &&
                        (widget.trip.referenceCurrency != null ||
                            _currency != null),
                    onChanged: (v) => setState(() => _currency = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ExpenseCategory>(
                    key: const ValueKey('expense_category_dropdown'),
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
                    onChanged: isSubmitting
                        ? null
                        : (v) {
                            if (v != null) setState(() => _category = v);
                          },
                  ),
                  const SizedBox(height: 12),
                  if (_payerDeviceId != null && widget.trip.members.isNotEmpty)
                    DropdownButtonFormField<String>(
                      key: const ValueKey('expense_payer_dropdown'),
                      value: _payerDeviceId,
                      decoration: const InputDecoration(
                        labelText: 'Who paid?',
                        border: OutlineInputBorder(),
                      ),
                      items: widget.trip.members
                          .map((m) => DropdownMenuItem(
                                value: m.memberId,
                                child: Text(m.isMe
                                    ? 'You (${m.displayName})'
                                    : m.displayName),
                              ))
                          .toList(),
                      onChanged: isSubmitting
                          ? null
                          : (v) {
                              if (v != null) setState(() => _payerDeviceId = v);
                            },
                    ),
                  const SizedBox(height: 8),
                  const ListTile(
                    enabled: false,
                    leading: Icon(Icons.attach_file),
                    title: Text('Attach receipt (coming soon)'),
                    dense: true,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    key: const ValueKey('expense_submit_button'),
                    onPressed: isSubmitting ? null : _submit,
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Add expense'),
                  ),
                  if (_submitErrorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _submitErrorMessage!,
                      key: const ValueKey('expense_submit_error_text'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
