import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../trip/domain/model/trip_model.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _showJoinDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Join a trip'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Paste the invitation link you received:'),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('home_join_link_field'),
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'https://...',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  key: const ValueKey('home_join_paste_button'),
                  icon: const Icon(Icons.paste),
                  tooltip: 'Paste from clipboard',
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null) {
                      controller.text = data!.text!;
                      controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: controller.text.length),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            key: const ValueKey('home_join_cancel_button'),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('home_join_submit_button'),
            onPressed: () {
              final parsed = _parseInviteLink(controller.text.trim());
              Navigator.of(dialogContext).pop();
              if (parsed == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid invitation link')),
                );
                return;
              }
              context.push('/trips/${parsed.$1}/join?token=${parsed.$2}');
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  /// Parses an invite URL like `http://host/trips/{tripId}/join?token={token}`
  /// Returns (tripId, token) or null if the link is invalid.
  (String, String)? _parseInviteLink(String raw) {
    try {
      final uri = Uri.parse(raw);
      final segments = uri.pathSegments;
      // expects [..., 'trips', tripId, 'join']
      final joinIdx = segments.indexOf('join');
      if (joinIdx < 1) return null;
      final tripId = segments[joinIdx - 1];
      final token = uri.queryParameters['token'] ?? '';
      if (tripId.isEmpty || token.isEmpty) return null;
      return (tripId, token);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PlanTogether'),
        actions: [
          IconButton(
            key: const ValueKey('home_join_link_button'),
            icon: const Icon(Icons.link),
            tooltip: 'Join with link',
            onPressed: () => _showJoinDialog(context),
          ),
          IconButton(
            key: const ValueKey('home_profile_button'),
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () => context.push(RouteConstants.profile),
          ),
          IconButton(
            key: const ValueKey('home_settings_button'),
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => context.push(RouteConstants.settings),
          ),
        ],
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(
                key: ValueKey('home_loading'),
                child: CircularProgressIndicator()),
            loading: () => const Center(
                key: ValueKey('home_loading'),
                child: CircularProgressIndicator()),
            failure: (message) => Center(
              key: const ValueKey('home_error_state'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Failed to load trips',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(message,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const ValueKey('home_retry_button'),
                    onPressed: () =>
                        context.read<HomeBloc>().add(const LoadTrips()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            loaded: (trips) => _TripListView(trips: trips),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('home_create_trip_fab'),
        onPressed: () => context.push(RouteConstants.createTrip),
        tooltip: 'New Trip',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TripListView extends StatelessWidget {
  final List<TripModel> trips;

  const _TripListView({required this.trips});

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return Center(
        key: const ValueKey('home_empty_state'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flight_takeoff,
                size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('No trips yet',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Tap + to plan your first trip',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    final activeTrips =
        trips.where((t) => t.status != 'ARCHIVED').toList();
    final archivedTrips =
        trips.where((t) => t.status == 'ARCHIVED').toList();

    return ListView(
      key: const ValueKey('home_trips_list'),
      padding: const EdgeInsets.all(16),
      children: [
        ...activeTrips.map((trip) => _TripCard(key: ValueKey('trip_card_${trip.id}'), trip: trip)),
        if (archivedTrips.isNotEmpty)
          ExpansionTile(
            title: const Text('Archived'),
            initiallyExpanded: false,
            children: archivedTrips
                .map((trip) => _TripCard(key: ValueKey('trip_card_${trip.id}'), trip: trip, isArchived: true))
                .toList(),
          ),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  final TripModel trip;
  final bool isArchived;

  const _TripCard({super.key, required this.trip, this.isArchived = false});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isArchived ? 0.7 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Row(
            children: [
              Expanded(child: Text(trip.title)),
              if (isArchived)
                Chip(
                  label: const Text('ARCHIVED'),
                  labelStyle: Theme.of(context).textTheme.labelSmall,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          subtitle: trip.description != null
              ? Text(trip.description!,
                  maxLines: 1, overflow: TextOverflow.ellipsis)
              : null,
          trailing: Text('${trip.memberCount} members',
              style: Theme.of(context).textTheme.bodySmall),
          onTap: () =>
              context.push('/trips/${trip.id}'),
        ),
      ),
    );
  }
}
