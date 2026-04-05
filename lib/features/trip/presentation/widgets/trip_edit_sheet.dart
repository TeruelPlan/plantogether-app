import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/model/trip_model.dart';
import '../bloc/trip_detail_bloc.dart';
import '../bloc/trip_detail_event.dart';

class TripEditSheet extends StatefulWidget {
  final TripModel trip;

  const TripEditSheet({super.key, required this.trip});

  static Future<void> show(BuildContext context, TripModel trip) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => BlocProvider.value(
        value: context.read<TripDetailBloc>(),
        child: TripEditSheet(trip: trip),
      ),
    );
  }

  @override
  State<TripEditSheet> createState() => _TripEditSheetState();
}

class _TripEditSheetState extends State<TripEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _currencyController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.trip.title);
    _descriptionController =
        TextEditingController(text: widget.trip.description ?? '');
    _currencyController =
        TextEditingController(text: widget.trip.referenceCurrency ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    context.read<TripDetailBloc>().add(UpdateTrip(
          tripId: widget.trip.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          currency: _currencyController.text.trim().isEmpty
              ? null
              : _currencyController.text.trim(),
        ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                'Edit trip',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _currencyController,
                decoration: const InputDecoration(
                  labelText: 'Reference currency',
                  hintText: 'EUR',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      !RegExp(r'^[A-Z]{3}$').hasMatch(value)) {
                    return 'Must be a 3-letter currency code (e.g. EUR)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _onSave,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
