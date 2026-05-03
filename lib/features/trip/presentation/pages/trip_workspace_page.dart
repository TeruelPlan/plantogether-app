import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../destination/presentation/bloc/destination_bloc.dart';
import '../../../destination/presentation/bloc/destination_event.dart';
import '../../../destination/presentation/bloc/destination_state.dart';
import '../../../destination/presentation/widgets/destinations_tab.dart';
import '../../../expense/presentation/page/expenses_tab.dart';
import '../../../poll/presentation/widgets/dates_tab.dart';
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
  String? _previousStatus;

  @override
  void initState() {
    super.initState();
    context.read<TripDetailBloc>().add(LoadTripDetail(tripId: widget.tripId));
    final destBloc = context.read<DestinationBloc>();
    destBloc.state.maybeWhen(
      initial: () {
        destBloc.add(LoadDestinations(widget.tripId));
        destBloc.add(LoadVoteConfig(widget.tripId));
      },
      orElse: () {},
    );
  }

  bool _isOrganizer(TripModel trip) {
    return trip.members.any((m) => m.isMe && m.role == 'ORGANIZER');
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
                    key: const ValueKey('trip_workspace_retry_button'),
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
            final myDisplayName = trip.members
                .where((m) => m.isMe)
                .map((m) => m.displayName)
                .firstOrNull;

            return DefaultTabController(
              length: 5,
              child: Scaffold(
                appBar: AppBar(
                  title: Text(trip.title),
                  leading: context.canPop()
                      ? null
                      : IconButton(
                          key: const ValueKey('trip_workspace_back_button'),
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => context.go('/home'),
                        ),
                  actions: [
                    if (isOrganizer && !isArchived)
                      IconButton(
                        key: const ValueKey('trip_workspace_invite_button'),
                        icon: const Icon(Icons.person_add),
                        tooltip: 'Invite members',
                        onPressed: () => context.push(
                          '/trips/${widget.tripId}/invite',
                          extra: trip.title,
                        ),
                      ),
                    if (isOrganizer && !isArchived)
                      IconButton(
                        key: const ValueKey('trip_workspace_edit_button'),
                        icon: const Icon(Icons.edit),
                        tooltip: 'Edit trip',
                        onPressed: () => TripEditSheet.show(context, trip),
                      ),
                    if (isOrganizer && !isArchived)
                      PopupMenuButton<String>(
                        key: const ValueKey('trip_workspace_menu_button'),
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
                      Tab(
                        key: ValueKey('trip_workspace_overview_tab'),
                        text: 'Overview',
                      ),
                      Tab(
                        key: ValueKey('trip_workspace_dates_tab'),
                        text: 'Dates',
                      ),
                      Tab(
                        key: ValueKey('trip_workspace_destinations_tab'),
                        text: 'Destinations',
                      ),
                      Tab(
                        key: ValueKey('trip_workspace_expenses_tab'),
                        text: 'Expenses',
                      ),
                      Tab(
                        key: ValueKey('trip_workspace_tasks_tab'),
                        text: 'Tasks',
                      ),
                    ],
                  ),
                ),
                body: TabBarView(
                  children: [
                    BlocBuilder<DestinationBloc, DestinationState>(
                      builder: (ctx, destState) {
                        final chosenName =
                            destState.chosenDestination?.name;
                        return OverviewTab(
                          trip: trip,
                          isArchived: isArchived,
                          chosenDestinationName: chosenName,
                          onInviteTap: isOrganizer
                              ? () => context.push(
                                    '/trips/${widget.tripId}/invite',
                                    extra: trip.title,
                                  )
                              : null,
                          onMembersTap: () {
                            final bloc = context.read<TripDetailBloc>();
                            context
                                .push('/trips/${widget.tripId}/members')
                                .then((_) => bloc.add(
                                      LoadTripDetail(tripId: widget.tripId),
                                    ));
                          },
                        );
                      },
                    ),
                    DatesTab(tripId: widget.tripId),
                    DestinationsTab(
                      tripId: widget.tripId,
                      isOrganizer: isOrganizer,
                      myDisplayName: myDisplayName,
                    ),
                    ExpensesTab(tripId: widget.tripId, trip: trip),
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
