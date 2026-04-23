import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../data/datasource/poll_remote_datasource.dart';
import '../bloc/poll_bloc.dart';
import '../bloc/poll_event.dart';
import '../bloc/poll_state.dart';

class CreatePollSheet extends StatefulWidget {
  final String tripId;

  const CreatePollSheet({super.key, required this.tripId});

  static Future<void> show(BuildContext context, String tripId) {
    final bloc = context.read<PollBloc>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => BlocProvider.value(
        value: bloc,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: CreatePollSheet(tripId: tripId),
        ),
      ),
    );
  }

  @override
  State<CreatePollSheet> createState() => _CreatePollSheetState();
}

class _CreatePollSheetState extends State<CreatePollSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final List<SlotInput> _slots = [];
  bool _showSlotError = false;
  bool _submitted = false;

  static final _dateFmt = DateFormat('MMM d, yyyy');

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _addSlot() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        _slots.add(SlotInput(startDate: picked.start, endDate: picked.end));
        _showSlotError = false;
      });
    }
  }

  void _removeSlot(int index) {
    setState(() => _slots.removeAt(index));
  }

  void _submit() {
    if (_slots.length < 2) {
      setState(() => _showSlotError = true);
      return;
    }
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _submitted = true);
    context.read<PollBloc>().add(CreatePoll(
          tripId: widget.tripId,
          title: _titleController.text.trim(),
          slots: List.unmodifiable(_slots),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PollBloc, PollState>(
      listener: (context, state) {
        state.whenOrNull(
          loaded: (_) {
            if (_submitted) Navigator.of(context).pop();
          },
          error: (message) {
            if (_submitted) {
              setState(() => _submitted = false);
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          },
        );
      },
      builder: (context, state) {
        final isLoading = state.maybeWhen(
          loading: () => true,
          orElse: () => false,
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Create date poll',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('create_poll_title_field'),
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),
                ..._slots.asMap().entries.map((e) => ListTile(
                      key: ValueKey('slot-${e.key}'),
                      leading: const Icon(Icons.date_range),
                      title: Text(
                        '${_dateFmt.format(e.value.startDate)} → ${_dateFmt.format(e.value.endDate)}',
                      ),
                      trailing: IconButton(
                        key: ValueKey('create_poll_remove_slot_${e.key}'),
                        icon: const Icon(Icons.close),
                        onPressed: () => _removeSlot(e.key),
                      ),
                    )),
                if (_showSlotError)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'At least 2 date slots are required',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const ValueKey('create_poll_add_slot_button'),
                  onPressed: _addSlot,
                  icon: const Icon(Icons.add),
                  label: const Text('Add date slot'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const ValueKey('create_poll_submit_button'),
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create poll'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

