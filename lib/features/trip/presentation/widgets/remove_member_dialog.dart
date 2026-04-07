import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/member_list_bloc.dart';
import '../bloc/member_list_event.dart';

class RemoveMemberDialog extends StatelessWidget {
  final String tripId;
  final String deviceId;
  final String displayName;

  const RemoveMemberDialog({
    super.key,
    required this.tripId,
    required this.deviceId,
    required this.displayName,
  });

  static Future<void> show(
    BuildContext context, {
    required String tripId,
    required String deviceId,
    required String displayName,
  }) {
    return showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<MemberListBloc>(),
        child: RemoveMemberDialog(
          tripId: tripId,
          deviceId: deviceId,
          displayName: displayName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded),
      title: Text('Remove $displayName?'),
      content: const Text(
        'This member will lose access to the trip and all its data.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () {
            context.read<MemberListBloc>().add(
                  RemoveMember(tripId: tripId, deviceId: deviceId),
                );
            Navigator.of(context).pop();
          },
          child: const Text('Remove'),
        ),
      ],
    );
  }
}
