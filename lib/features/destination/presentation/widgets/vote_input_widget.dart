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
  final bool isVoteCast;
  final int totalDestinationCount;
  final bool disabled;

  const VoteInputWidget({
    super.key,
    required this.tripId,
    required this.destination,
    required this.mode,
    required this.totalDestinationCount,
    this.myRankForThisDestination,
    this.isVoteCast = false,
    this.disabled = false,
  });

  void _castSimple(BuildContext context) {
    if (isVoteCast) {
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
    final body = _buildBody(context);
    if (!disabled) return body;
    return Tooltip(
      key: ValueKey('vote_input_disabled_${destination.id}'),
      message: 'Selection locked — destination chosen',
      child: AbsorbPointer(child: Opacity(opacity: 0.5, child: body)),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (mode) {
      case VoteMode.simple:
        return InkWell(
          key: const ValueKey('vote_simple_row'),
          onTap: disabled ? null : () => _castSimple(context),
          child: Row(
            children: [
              IconButton(
                key: const ValueKey('vote_simple_button'),
                tooltip: isVoteCast ? 'Retract vote' : 'Vote',
                icon: Icon(
                  isVoteCast
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                onPressed: disabled ? null : () => _castSimple(context),
              ),
              Text(isVoteCast ? 'Your pick' : 'Pick this'),
              const Spacer(),
              _votesCountBadge(context),
            ],
          ),
        );
      case VoteMode.approval:
        return InkWell(
          key: const ValueKey('vote_approval_row'),
          onTap:
              disabled ? null : () => _toggleApproval(context, !isVoteCast),
          child: Row(
            children: [
              Checkbox(
                key: const ValueKey('vote_approval_checkbox'),
                value: isVoteCast,
                onChanged:
                    disabled ? null : (v) => _toggleApproval(context, v),
              ),
              const Text('Approve'),
              const Spacer(),
              _votesCountBadge(context),
            ],
          ),
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
              key: const ValueKey('vote_ranking_dropdown'),
              value: myRankForThisDestination,
              items: items,
              onChanged: disabled ? null : (v) => _chooseRank(context, v),
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
