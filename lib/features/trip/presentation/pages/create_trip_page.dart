import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/create_trip_bloc.dart';
import '../bloc/create_trip_event.dart';
import '../bloc/create_trip_state.dart';

class CreateTripPage extends StatefulWidget {
  const CreateTripPage({super.key});

  @override
  State<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends State<CreateTripPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCurrency;
  final _formKey = GlobalKey<FormState>();

  static const _currencies = ['EUR', 'USD', 'GBP', 'CHF', 'JPY'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateTripBloc, CreateTripState>(
      listener: (context, state) {
        state.whenOrNull(
          success: (trip) => context.pushReplacement('/trips/${trip.id}', extra: trip),
          failure: (message) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('New Trip')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Trip name',
                    hintText: 'e.g. Summer Road Trip',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Trip name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCurrency,
                  decoration: const InputDecoration(
                    labelText: 'Currency (optional)',
                  ),
                  items: _currencies
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedCurrency = value);
                  },
                ),
                const SizedBox(height: 24),
                BlocBuilder<CreateTripBloc, CreateTripState>(
                  builder: (context, state) {
                    final isLoading = state.maybeWhen(
                      loading: () => true,
                      orElse: () => false,
                    );
                    return FilledButton(
                      onPressed: isLoading ? null : _onSubmit,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create Trip'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<CreateTripBloc>().add(SubmitCreateTrip(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          currency: _selectedCurrency,
        ));
  }
}
