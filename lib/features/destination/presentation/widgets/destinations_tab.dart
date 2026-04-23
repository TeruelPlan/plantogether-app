import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/model/destination_model.dart';
import '../../domain/model/vote_config_model.dart';
import '../bloc/destination_bloc.dart';
import '../bloc/destination_event.dart';
import '../bloc/destination_state.dart';
import 'destination_proposal_card.dart';
import 'propose_destination_sheet.dart';
import 'vote_input_widget.dart';
import 'vote_mode_selector.dart';

class DestinationsTab extends StatefulWidget {
  final String tripId;
  final bool isOrganizer;

  const DestinationsTab({
    super.key,
    required this.tripId,
    this.isOrganizer = false,
  });

  @override
  State<DestinationsTab> createState() => _DestinationsTabState();
}

class _DestinationsTabState extends State<DestinationsTab> {
  bool _sheetOpen = false;
  DestinationState? _lastState;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<DestinationBloc>();
    bloc.state.maybeWhen(
      initial: () {
        bloc.add(LoadDestinations(widget.tripId));
        bloc.add(LoadVoteConfig(widget.tripId));
      },
      orElse: () {},
    );
  }

  Future<void> _openSheet() async {
    if (_sheetOpen) return;
    setState(() => _sheetOpen = true);
    try {
      await ProposeDestinationSheet.show(context, widget.tripId);
    } finally {
      if (mounted) setState(() => _sheetOpen = false);
    }
  }

  int? _myRankFor(DestinationModel destination, String? myDeviceId) {
    // Rank from the aggregate is not available per-device; this is a
    // placeholder until per-voter enrichment arrives. Keep null for now.
    // TODO: populate from enriched aggregate -> 4.3
    return null;
  }

  bool _isMySimpleChoice(DestinationModel destination, String? myDeviceId) {
    // Same placeholder: per-device state unknown until enrichment.
    return false;
  }

  bool _isMyApproval(DestinationModel destination, String? myDeviceId) {
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<DestinationBloc, DestinationState>(
        listener: (ctx, state) {
          // Show a SnackBar on transient errors (e.g. UpdateVoteConfig 403).
          final prev = _lastState;
          state.maybeWhen(
            error: (message) {
              final wasLoaded = prev != null &&
                  prev.maybeWhen(loaded: (a, b, c) => true, orElse: () => false);
              if (wasLoaded) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              }
            },
            orElse: () {},
          );
          _lastState = state;
        },
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (message) => _buildError(context, message),
            loaded: (destinations, mode, myDeviceId) => Column(
              children: [
                VoteModeSelector(
                  tripId: widget.tripId,
                  currentMode: mode,
                  isOrganizer: widget.isOrganizer,
                  destinations: destinations,
                ),
                Expanded(
                  child: destinations.isEmpty
                      ? _buildEmpty(context)
                      : ListView.builder(
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
                          itemCount: destinations.length,
                          itemBuilder: (_, i) {
                            final d = destinations[i];
                            final effectiveMode = mode ?? VoteMode.simple;
                            return DestinationProposalCard(
                              destination: d,
                              voteInput: VoteInputWidget(
                                tripId: widget.tripId,
                                destination: d,
                                mode: effectiveMode,
                                totalDestinationCount: destinations.length,
                                myRankForThisDestination:
                                    _myRankFor(d, myDeviceId),
                                isMySimpleChoice:
                                    _isMySimpleChoice(d, myDeviceId),
                                isMyApproval: _isMyApproval(d, myDeviceId),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openSheet,
        tooltip: 'Propose destination',
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Propose destination'),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Failed to load destinations',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(message, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final bloc = context.read<DestinationBloc>();
              bloc.add(LoadDestinations(widget.tripId));
              bloc.add(LoadVoteConfig(widget.tripId));
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.explore_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Where are you going? · Propose a destination',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

