import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../trip/domain/model/trip_model.dart';
import '../../domain/entity/task.dart';
import '../../domain/repository/task_repository.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';

Future<void> showAddTaskSheet(
  BuildContext context, {
  required String tripId,
  required TripModel trip,
  required TaskBloc taskBloc,
  String? parentTaskId,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider.value(
      value: taskBloc,
      child: _AddTaskSheet(
        tripId: tripId,
        trip: trip,
        parentTaskId: parentTaskId,
      ),
    ),
  );
}

class _AddTaskSheet extends StatefulWidget {
  final String tripId;
  final TripModel trip;
  final String? parentTaskId;

  const _AddTaskSheet({
    required this.tripId,
    required this.trip,
    this.parentTaskId,
  });

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TaskPriority _priority = TaskPriority.medium;
  String? _assigneeId;
  DateTime? _deadline;
  bool _createRequested = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _createRequested = true;
    context.read<TaskBloc>().add(
          CreateTask(
            tripId: widget.tripId,
            input: CreateTaskInput(
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              assigneeId: _assigneeId,
              priority: _priority,
              deadline: _deadline,
              parentTaskId: widget.parentTaskId,
            ),
          ),
        );
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (!mounted) return;
    if (picked != null) setState(() => _deadline = picked);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TaskBloc, TaskState>(
      listener: (context, state) {
        state.maybeWhen(
          loaded: (_) {
            if (_createRequested) {
              _createRequested = false;
              Navigator.of(context).pop();
            }
          },
          error: (message) {
            _createRequested = false;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          },
          orElse: () {},
        );
      },
      child: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          final isLoading = state.maybeWhen(
            loading: () => true,
            orElse: () => false,
          );

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.parentTaskId != null ? 'Add subtask' : 'New task',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('task_title_field'),
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title *',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 255,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return widget.parentTaskId != null
                            ? 'Subtask title is required'
                            : 'Task title is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TaskPriority>(
                    key: const ValueKey('task_priority_dropdown'),
                    value: _priority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                    ),
                    items: TaskPriority.values
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.name[0].toUpperCase() +
                                p.name.substring(1)),
                          ),
                        )
                        .toList(),
                    onChanged: (p) {
                      if (p != null) setState(() => _priority = p);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    key: const ValueKey('task_assignee_dropdown'),
                    value: _assigneeId,
                    decoration: const InputDecoration(
                      labelText: 'Assignee',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Unassigned'),
                      ),
                      ...widget.trip.members.map(
                        (m) => DropdownMenuItem(
                          value: m.memberId,
                          child: Text(m.displayName),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _assigneeId = v),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    key: const ValueKey('task_deadline_picker'),
                    onTap: _pickDeadline,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Deadline (optional)',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _deadline == null
                            ? 'No deadline'
                            : '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey('task_description_field'),
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    maxLength: 4000,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      key: const ValueKey('task_submit_button'),
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create task'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
