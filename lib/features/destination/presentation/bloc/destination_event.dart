import 'package:equatable/equatable.dart';

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
