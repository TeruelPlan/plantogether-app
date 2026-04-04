import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/invite_bloc.dart';
import '../bloc/invite_event.dart';
import '../bloc/invite_state.dart';
import '../widgets/qr_invite_display_widget.dart';

class InvitePage extends StatelessWidget {
  final String tripId;
  final String tripName;

  const InvitePage({
    super.key,
    required this.tripId,
    required this.tripName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Invite to $tripName')),
      body: BlocBuilder<InviteBloc, InviteState>(
        builder: (context, state) {
          return state.when(
            initial: () => const SizedBox.shrink(),
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            loaded: (invitation) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: QRInviteDisplayWidget(
                  inviteUrl: invitation.inviteUrl,
                  tripName: tripName,
                ),
              ),
            ),
            failure: (message) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(message,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context
                        .read<InviteBloc>()
                        .add(LoadInvitation(tripId: tripId)),
                    child: const Text('Retry'),
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
