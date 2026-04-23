import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/model/destination_model.dart';
import '../../domain/model/vote_config_model.dart';
import '../bloc/destination_bloc.dart';
import '../bloc/destination_event.dart';

/// Displays a segmented selector for organizers to choose the vote mode,
/// or a read-only Chip for participants.
class VoteModeSelector extends StatelessWidget {
  final String tripId;
  final VoteMode? currentMode;
  final bool isOrganizer;
  final List<DestinationModel> destinations;

  const VoteModeSelector({
    super.key,
    required this.tripId,
    required this.currentMode,
    required this.isOrganizer,
    required this.destinations,
  });

  bool get _hasExistingVotes =>
      destinations.any((d) => d.votes.totalVotes > 0);

  Future<void> _handleSelection(
    BuildContext context,
    VoteMode newMode,
  ) async {
    if (newMode == currentMode) return;
    // Confirm when switching TO SIMPLE or APPROVAL from RANKING with existing votes.
    final needsConfirmation = currentMode == VoteMode.ranking &&
        (newMode == VoteMode.simple || newMode == VoteMode.approval) &&
        _hasExistingVotes;
    if (needsConfirmation) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Switch vote mode?'),
          content: const Text(
            'Switching from Ranking will clear existing rank values. '
            'Voters will remain counted but their ranks will be reset.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Switch'),
            ),
          ],
        ),
      );
      if (!context.mounted) return;
      if (confirmed != true) return;
    }
    context
        .read<DestinationBloc>()
        .add(UpdateVoteConfig(tripId: tripId, mode: newMode));
  }

  String _labelFor(VoteMode mode) {
    switch (mode) {
      case VoteMode.simple:
        return 'Simple';
      case VoteMode.approval:
        return 'Approval';
      case VoteMode.ranking:
        return 'Ranking';
    }
  }

  @override
  Widget build(BuildContext context) {
    final effective = currentMode ?? VoteMode.simple;
    if (!isOrganizer) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Chip(
            avatar: const Icon(Icons.how_to_vote_outlined, size: 18),
            label: Text('Vote mode: ${_labelFor(effective)}'),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SegmentedButton<VoteMode>(
        segments: const [
          ButtonSegment(
            value: VoteMode.simple,
            label: Text('Simple'),
            icon: Icon(Icons.radio_button_checked),
          ),
          ButtonSegment(
            value: VoteMode.approval,
            label: Text('Approval'),
            icon: Icon(Icons.check_box_outlined),
          ),
          ButtonSegment(
            value: VoteMode.ranking,
            label: Text('Ranking'),
            icon: Icon(Icons.format_list_numbered),
          ),
        ],
        selected: {effective},
        onSelectionChanged: (selection) {
          final next = selection.first;
          _handleSelection(context, next);
        },
      ),
    );
  }
}
