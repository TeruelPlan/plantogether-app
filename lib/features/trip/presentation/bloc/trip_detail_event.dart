import 'package:equatable/equatable.dart';

abstract class TripDetailEvent extends Equatable {
  const TripDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadTripDetail extends TripDetailEvent {
  final String tripId;

  const LoadTripDetail({required this.tripId});

  @override
  List<Object?> get props => [tripId];
}
