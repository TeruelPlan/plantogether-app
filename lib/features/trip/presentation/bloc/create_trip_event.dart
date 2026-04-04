import 'package:equatable/equatable.dart';

abstract class CreateTripEvent extends Equatable {
  const CreateTripEvent();

  @override
  List<Object?> get props => [];
}

class SubmitCreateTrip extends CreateTripEvent {
  final String title;
  final String? description;
  final String? currency;

  const SubmitCreateTrip({
    required this.title,
    this.description,
    this.currency,
  });

  @override
  List<Object?> get props => [title, description, currency];
}
