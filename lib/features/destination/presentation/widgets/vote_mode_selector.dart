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

  bool get _hasAnyVotes => destinations.any((d) => d.votes.totalVotes > 0);

  Future<void> _handleSelection(
    BuildContext context,
    VoteMode newMode,) async {
    if (newMode == currentMode) return;
    // Confirmation cases:
    ///   - RANKING -> SIMPLE / APPROVAL with existing ranked votes: ranks will be cleared.
    //   - APPROVAL -> SIMPLE with existing approvals: members may hold several approvals
    //     that collapse into an ambiguous "one vote per trip" constraint.
    //   - SIMPLE / APPROVAL -> RANKING with existing votes: members must re-rank explicitly.
    String? warning;
    if (currentMode == VoteMode.ranking &&
        ((newMode == VoteMode.simple || newMode == VoteMode.approval) &&
            _hasAnyVotes)) {
      warning = 'Switching from Ranking will clear existing rank values. '
          'Voters will remain counted but their ranks will be reset.';
    } else if (currentMode == VoteMode.approval &&
        newMode == VoteMode.simple &&
        _hasAnyVotes) {
      warning = 'Switching from Approval to Simple keeps existing approvals '
          'but voters may now hold more than one pick in Simple mode until '
          'they re-vote.';
    } else if ((currentMode == VoteMode.simple ||
        currentMode == VoteMode.approval) &&
        newMode == VoteMode.ranking &&
        _hasAnyVotes) {
      warning = 'Switching to Ranking preserves existing votes but voters '
          'will need to explicitly choose a rank for each destination.';
    }

    if (warning != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Switch vote mode?'),
          content: Text(warning!),
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
        key: const ValueKey('vote_mode_selector'),
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
