import 'package:equatable/equatable.dart';

abstract class JoinTripEvent extends Equatable {
  const JoinTripEvent();

  @override
  List<Object?> get props => [];
}

class LoadPreview extends JoinTripEvent {
  final String tripId;
  final String token;

  const LoadPreview({required this.tripId, required this.token});

  @override
  List<Object?> get props => [tripId, token];
}

class SubmitJoin extends JoinTripEvent {
  final String tripId;
  final String token;

  const SubmitJoin({required this.tripId, required this.token});

  @override
  List<Object?> get props => [tripId, token];
}
