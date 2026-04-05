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

class UpdateTrip extends TripDetailEvent {
  final String tripId;
  final String title;
  final String? description;
  final String? currency;

  const UpdateTrip({
    required this.tripId,
    required this.title,
    this.description,
    this.currency,
  });

  @override
  List<Object?> get props => [tripId, title, description, currency];
}

class ArchiveTrip extends TripDetailEvent {
  final String tripId;

  const ArchiveTrip({required this.tripId});

  @override
  List<Object?> get props => [tripId];
}
