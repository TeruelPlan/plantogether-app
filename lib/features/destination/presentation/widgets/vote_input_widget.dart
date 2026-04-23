import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/model/destination_model.dart';
import '../../domain/model/vote_config_model.dart';
import '../bloc/destination_bloc.dart';
import '../bloc/destination_event.dart';

/// Per-destination vote input widget, rendered at the bottom of a
/// [DestinationProposalCard]. Behavior depends on [mode].
class VoteInputWidget extends StatelessWidget {
  final String tripId;
  final DestinationModel destination;
  final VoteMode mode;
  final int? myRankForThisDestination;
  final bool isMySimpleChoice;
  final bool isMyApproval;
  final int totalDestinationCount;

  const VoteInputWidget({
    super.key,
    required this.tripId,
    required this.destination,
    required this.mode,
    required this.totalDestinationCount,
    this.myRankForThisDestination,
    this.isMySimpleChoice = false,
    this.isMyApproval = false,
  });

  void _castSimple(BuildContext context) {
    if (isMySimpleChoice) {
      context
          .read<DestinationBloc>()
          .add(RetractVote(tripId: tripId, destinationId: destination.id));
    } else {
      context
          .read<DestinationBloc>()
          .add(CastVote(tripId: tripId, destinationId: destination.id));
    }
  }

  void _toggleApproval(BuildContext context, bool? value) {
    if (value == true) {
      context
          .read<DestinationBloc>()
          .add(CastVote(tripId: tripId, destinationId: destination.id));
    } else {
      context
          .read<DestinationBloc>()
          .add(RetractVote(tripId: tripId, destinationId: destination.id));
    }
  }

  void _chooseRank(BuildContext context, int? rank) {
    if (rank == null) {
      context
          .read<DestinationBloc>()
          .add(RetractVote(tripId: tripId, destinationId: destination.id));
    } else {
      context.read<DestinationBloc>().add(CastVote(
            tripId: tripId,
            destinationId: destination.id,
            rank: rank,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case VoteMode.simple:
        return Row(
          key: const ValueKey('vote_input_simple'),
          children: [
            IconButton(
              tooltip: isMySimpleChoice ? 'Retract vote' : 'Vote',
              icon: Icon(
                isMySimpleChoice
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              onPressed: () => _castSimple(context),
            ),
            Text(isMySimpleChoice ? 'Your pick' : 'Pick this'),
            const Spacer(),
            _votesCountBadge(context),
          ],
        );
      case VoteMode.approval:
        return Row(
          key: const ValueKey('vote_input_approval'),
          children: [
            Checkbox(
              value: isMyApproval,
              onChanged: (v) => _toggleApproval(context, v),
            ),
            const Text('Approve'),
            const Spacer(),
            _votesCountBadge(context),
          ],
        );
      case VoteMode.ranking:
        final items = <DropdownMenuItem<int?>>[
          const DropdownMenuItem<int?>(
            value: null,
            child: Text('Unranked'),
          ),
          for (var i = 1; i <= totalDestinationCount; i++)
            DropdownMenuItem<int?>(value: i, child: Text('Rank $i')),
        ];
        return Row(
          key: const ValueKey('vote_input_ranking'),
          children: [
            const Text('Your rank:'),
            const SizedBox(width: 8),
            DropdownButton<int?>(
              value: myRankForThisDestination,
              items: items,
              onChanged: (v) => _chooseRank(context, v),
            ),
            const Spacer(),
            _votesCountBadge(context),
          ],
        );
    }
  }

  Widget _votesCountBadge(BuildContext context) {
    final total = destination.votes.totalVotes;
    if (total <= 0) return const SizedBox.shrink();
    return Text(
      '$total vote${total == 1 ? '' : 's'}',
      style: Theme.of(context).textTheme.labelSmall,
    );
  }
}
