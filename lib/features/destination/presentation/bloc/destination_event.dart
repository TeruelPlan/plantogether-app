import 'package:equatable/equatable.dart';

import '../../domain/model/vote_config_model.dart';
import '../../domain/repository/destination_repository.dart';

abstract class DestinationEvent extends Equatable {
  const DestinationEvent();

  @override
  List<Object?> get props => [];
}

class LoadDestinations extends DestinationEvent {
  final String tripId;

  const LoadDestinations(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

class ProposeDestination extends DestinationEvent {
  final String tripId;
  final ProposeDestinationInput input;

  const ProposeDestination({required this.tripId, required this.input});

  @override
  List<Object?> get props => [tripId, input];
}

class LoadVoteConfig extends DestinationEvent {
  final String tripId;

  const LoadVoteConfig(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

class UpdateVoteConfig extends DestinationEvent {
  final String tripId;
  final VoteMode mode;

  const UpdateVoteConfig({required this.tripId, required this.mode});

  @override
  List<Object?> get props => [tripId, mode];
}

class CastVote extends DestinationEvent {
  final String tripId;
  final String destinationId;
  final int? rank;

  const CastVote({
    required this.tripId,
    required this.destinationId,
    this.rank,
  });

  @override
  List<Object?> get props => [tripId, destinationId, rank];
}

class RetractVote extends DestinationEvent {
  final String tripId;
  final String destinationId;

  const RetractVote({required this.tripId, required this.destinationId});

  @override
  List<Object?> get props => [tripId, destinationId];
}
