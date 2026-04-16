import 'package:equatable/equatable.dart';

import '../../data/datasource/poll_remote_datasource.dart';

abstract class PollEvent extends Equatable {
  const PollEvent();

  @override
  List<Object?> get props => [];
}

class LoadPolls extends PollEvent {
  final String tripId;

  const LoadPolls(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

class CreatePoll extends PollEvent {
  final String tripId;
  final String title;
  final List<SlotInput> slots;

  const CreatePoll({
    required this.tripId,
    required this.title,
    required this.slots,
  });

  @override
  List<Object?> get props => [
        tripId,
        title,
        slots.map((s) => '${s.startDate.toIso8601String()}/${s.endDate.toIso8601String()}').toList(),
      ];
}
