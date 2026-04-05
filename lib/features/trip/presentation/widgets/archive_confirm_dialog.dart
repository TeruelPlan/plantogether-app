import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/trip_detail_bloc.dart';
import '../bloc/trip_detail_event.dart';

class ArchiveConfirmDialog extends StatelessWidget {
  final String tripId;

  const ArchiveConfirmDialog({super.key, required this.tripId});

  static Future<bool?> show(BuildContext context, String tripId) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<TripDetailBloc>(),
        child: ArchiveConfirmDialog(tripId: tripId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Icon(Icons.archive, color: colorScheme.error),
      title: const Text('Archive this trip?'),
      content: const Text(
        'Archived trips are read-only. Members can still view all trip data.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
          ),
          onPressed: () {
            context.read<TripDetailBloc>().add(ArchiveTrip(tripId: tripId));
            Navigator.of(context).pop(true);
          },
          child: const Text('Archive'),
        ),
      ],
    );
  }
}
