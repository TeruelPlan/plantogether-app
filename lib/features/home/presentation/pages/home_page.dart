import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../trip/domain/model/trip_model.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PlanTogether'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () => context.go(RouteConstants.profile),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => context.push(RouteConstants.settings),
          ),
        ],
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(child: CircularProgressIndicator()),
            failure: (message) => Center(
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
      padding: const EdgeInsets.all(16),
      children: [
        ...activeTrips.map((trip) => _TripCard(trip: trip)),
        if (archivedTrips.isNotEmpty)
          ExpansionTile(
            title: const Text('Archived'),
            initiallyExpanded: false,
            children: archivedTrips
                .map((trip) => _TripCard(trip: trip, isArchived: true))
                .toList(),
          ),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  final TripModel trip;
  final bool isArchived;

  const _TripCard({required this.trip, this.isArchived = false});

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
