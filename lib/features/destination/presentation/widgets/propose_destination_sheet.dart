import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repository/destination_repository.dart';
import '../bloc/destination_bloc.dart';
import '../bloc/destination_event.dart';
import '../bloc/destination_state.dart';

class ProposeDestinationSheet extends StatefulWidget {
  final String tripId;

  const ProposeDestinationSheet({super.key, required this.tripId});

  static Future<void> show(BuildContext context, String tripId) {
    final bloc = context.read<DestinationBloc>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: ProposeDestinationSheet(tripId: tripId),
      ),
    );
  }

  @override
  State<ProposeDestinationSheet> createState() =>
      _ProposeDestinationSheetState();
}

class _ProposeDestinationSheetState extends State<ProposeDestinationSheet> {
  static const _currencies = ['EUR', 'USD', 'GBP', 'CHF', 'JPY'];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _urlController = TextEditingController();
  String? _currency;
  bool _submitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return 'Enter a valid http:// or https:// URL';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final budgetText = _budgetController.text.trim();
    final urlText = _urlController.text.trim();
    final descText = _descriptionController.text.trim();

    final input = ProposeDestinationInput(
      name: _nameController.text.trim(),
      description: descText.isEmpty ? null : descText,
      estimatedBudget: budgetText.isEmpty ? null : double.tryParse(budgetText),
      currency: _currency,
      externalUrl: urlText.isEmpty ? null : urlText,
    );

    setState(() => _submitted = true);
    context
        .read<DestinationBloc>()
        .add(ProposeDestination(tripId: widget.tripId, input: input));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return BlocListener<DestinationBloc, DestinationState>(
      listener: (context, state) {
        if (!_submitted) return;
        state.maybeWhen(
          loaded: (_, _, _, _, _) {
            if (!mounted) return;
            Navigator.of(context).pop();
          },
          error: (message) {
            if (!mounted) return;
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(message)));
            setState(() => _submitted = false);
          },
          orElse: () {},
        );
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Propose a destination',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('propose_name_field'),
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Destination name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('propose_description_field'),
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const ValueKey('propose_budget_field'),
                        controller: _budgetController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Estimated budget',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          if (double.tryParse(v.trim()) == null) {
                            return 'Must be a number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: DropdownButtonFormField<String>(
                        key: const ValueKey('propose_currency_dropdown'),
                        initialValue: _currency,
                        decoration: const InputDecoration(
                          labelText: 'Currency',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('—'),
                          ),
                          ..._currencies.map((c) =>
                              DropdownMenuItem(value: c, child: Text(c))),
                        ],
                        onChanged: (value) => setState(() => _currency = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('propose_url_field'),
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'External URL',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateUrl,
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.add_a_photo_outlined),
                  title: const Text('Add photo (coming soon)'),
                  enabled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const ValueKey('propose_submit_button'),
                  onPressed: _submitted ? null : _submit,
                  child: Text(_submitted ? 'Proposing…' : 'Propose'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
