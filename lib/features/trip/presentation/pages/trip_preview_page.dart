import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/join_trip_bloc.dart';
import '../bloc/join_trip_event.dart';
import '../bloc/join_trip_state.dart';

class TripPreviewPage extends StatelessWidget {
  final String tripId;
  final String token;

  const TripPreviewPage({
    super.key,
    required this.tripId,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Preview')),
      body: BlocConsumer<JoinTripBloc, JoinTripState>(
        listener: (context, state) {
          state.whenOrNull(
            joined: (trip) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Joined ${trip.title}!')),
              );
              context.go('/trips/${trip.id}');
            },
          );
        },
        builder: (context, state) {
          return state.when(
            initial: () => const SizedBox.shrink(),
            loadingPreview: () =>
                const Center(child: CircularProgressIndicator()),
            previewLoaded: (preview) => Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  Text(
                    preview.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (preview.description != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      preview.description!,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline),
                      const SizedBox(width: 8),
                      Text(
                        '${preview.memberCount} member${preview.memberCount == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  FilledButton.icon(
                    key: const ValueKey('trip_preview_join_button'),
                    icon: const Icon(Icons.group_add),
                    label: const Text('Join trip'),
                    onPressed: () => context.read<JoinTripBloc>().add(
                          SubmitJoin(tripId: tripId, token: token),
                        ),
                  ),
                ],
              ),
            ),
            joining: () => const Center(child: CircularProgressIndicator()),
            joined: (_) =>
                const Center(child: CircularProgressIndicator()),
            failure: (message) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(message,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const ValueKey('trip_preview_retry_button'),
                    onPressed: () => context.read<JoinTripBloc>().add(
                          LoadPreview(tripId: tripId, token: token),
                        ),
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
