import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/trip_detail_bloc.dart';
import '../bloc/trip_detail_event.dart';
import '../bloc/trip_detail_state.dart';
import '../widgets/overview_tab.dart';

class TripWorkspacePage extends StatefulWidget {
  final String tripId;

  const TripWorkspacePage({
    super.key,
    required this.tripId,
  });

  @override
  State<TripWorkspacePage> createState() => _TripWorkspacePageState();
}

class _TripWorkspacePageState extends State<TripWorkspacePage> {
  @override
  void initState() {
    super.initState();
    context.read<TripDetailBloc>().add(LoadTripDetail(tripId: widget.tripId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripDetailBloc, TripDetailState>(
      builder: (context, state) {
        return state.when(
          initial: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          failure: (message) => Scaffold(
            appBar: AppBar(title: const Text('Trip')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Failed to load trip', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(message, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context
                        .read<TripDetailBloc>()
                        .add(LoadTripDetail(tripId: widget.tripId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          loaded: (trip) => DefaultTabController(
            length: 5,
            child: Scaffold(
              appBar: AppBar(
                title: Text(trip.title),
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Overview'),
                    Tab(text: 'Dates'),
                    Tab(text: 'Destinations'),
                    Tab(text: 'Expenses'),
                    Tab(text: 'Tasks'),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  OverviewTab(trip: trip),
                  const Center(child: Text('Dates')),
                  const Center(child: Text('Destinations')),
                  const Center(child: Text('Expenses')),
                  const Center(child: Text('Tasks')),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
