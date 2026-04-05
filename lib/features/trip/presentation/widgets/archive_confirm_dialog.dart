import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/trip_detail_bloc.dart';
import '../bloc/trip_detail_event.dart';
import '../bloc/trip_detail_state.dart';

class ArchiveConfirmDialog extends StatefulWidget {
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
  State<ArchiveConfirmDialog> createState() => _ArchiveConfirmDialogState();
}

class _ArchiveConfirmDialogState extends State<ArchiveConfirmDialog> {
  bool _archiving = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<TripDetailBloc, TripDetailState>(
      listener: (context, state) {
        state.when(
          initial: () {},
          loading: () {},
          loaded: (trip) {
            if (trip.status == 'ARCHIVED') {
              Navigator.of(context).pop(true);
            }
          },
          failure: (message) {
            setState(() => _archiving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          },
        );
      },
      child: AlertDialog(
        icon: Icon(Icons.archive, color: colorScheme.error),
        title: const Text('Archive this trip?'),
        content: const Text(
          'Archived trips are read-only. Members can still view all trip data.',
        ),
        actions: [
          TextButton(
            onPressed: _archiving ? null : () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
            ),
            onPressed: _archiving
                ? null
                : () {
                    setState(() => _archiving = true);
                    context
                        .read<TripDetailBloc>()
                        .add(ArchiveTrip(tripId: widget.tripId));
                  },
            child: _archiving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Archive'),
          ),
        ],
      ),
    );
  }
}
