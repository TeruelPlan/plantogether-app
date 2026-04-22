import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/destination_bloc.dart';
import '../bloc/destination_event.dart';
import '../bloc/destination_state.dart';
import 'destination_proposal_card.dart';
import 'propose_destination_sheet.dart';

class DestinationsTab extends StatefulWidget {
  final String tripId;

  const DestinationsTab({super.key, required this.tripId});

  @override
  State<DestinationsTab> createState() => _DestinationsTabState();
}

class _DestinationsTabState extends State<DestinationsTab> {
  bool _sheetOpen = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<DestinationBloc>().state;
    state.maybeWhen(
      initial: () => context
          .read<DestinationBloc>()
          .add(LoadDestinations(widget.tripId)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<DestinationBloc, DestinationState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (message) => _buildError(context, message),
            loaded: (destinations) => destinations.isEmpty
                ? _buildEmpty(context)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: destinations.length,
                    itemBuilder: (_, i) => DestinationProposalCard(
                      destination: destinations[i],
                    ),
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
            onPressed: () => context
                .read<DestinationBloc>()
                .add(LoadDestinations(widget.tripId)),
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
