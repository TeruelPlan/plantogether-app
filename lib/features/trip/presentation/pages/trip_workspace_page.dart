import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/security/device_id_service.dart';
import '../../domain/model/trip_model.dart';
import '../bloc/trip_detail_bloc.dart';
import '../bloc/trip_detail_event.dart';
import '../bloc/trip_detail_state.dart';
import '../widgets/archive_confirm_dialog.dart';
import '../widgets/overview_tab.dart';
import '../widgets/trip_edit_sheet.dart';

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
  String? _deviceId;
  String? _previousStatus;

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
    context.read<TripDetailBloc>().add(LoadTripDetail(tripId: widget.tripId));
  }

  Future<void> _loadDeviceId() async {
    final id = await context.read<DeviceIdService>().getDeviceId();
    if (mounted) setState(() => _deviceId = id);
  }

  bool _isOrganizer(TripModel trip) {
    if (_deviceId == null) return false;
    return trip.members.any(
      (m) => m.deviceId == _deviceId && m.role == 'ORGANIZER',
    );
  }

  bool _isArchived(TripModel trip) => trip.status == 'ARCHIVED';

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripDetailBloc, TripDetailState>(
      listener: (context, state) {
        state.whenOrNull(
          loaded: (trip) {
            if (_previousStatus != null &&
                _previousStatus != 'ARCHIVED' &&
                trip.status == 'ARCHIVED') {
              context.go('/home');
            }
            _previousStatus = trip.status;
          },
        );
      },
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
          loaded: (trip) {
            final isOrganizer = _isOrganizer(trip);
            final isArchived = _isArchived(trip);

            return DefaultTabController(
              length: 5,
              child: Scaffold(
                appBar: AppBar(
                  title: Text(trip.title),
                  actions: [
                    if (isOrganizer && !isArchived)
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: 'Edit trip',
                        onPressed: () => TripEditSheet.show(context, trip),
                      ),
                    if (isOrganizer && !isArchived)
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'archive') {
                            ArchiveConfirmDialog.show(context, trip.id);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'archive',
                            child: Text('Archive trip'),
                          ),
                        ],
                      ),
                  ],
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
                    OverviewTab(trip: trip, isArchived: isArchived),
                    const Center(child: Text('Dates')),
                    const Center(child: Text('Destinations')),
                    const Center(child: Text('Expenses')),
                    const Center(child: Text('Tasks')),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
