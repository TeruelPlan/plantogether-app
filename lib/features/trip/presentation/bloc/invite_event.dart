import 'package:equatable/equatable.dart';

abstract class InviteEvent extends Equatable {
  const InviteEvent();

  @override
  List<Object?> get props => [];
}

class LoadInvitation extends InviteEvent {
  final String tripId;

  const LoadInvitation({required this.tripId});

  @override
  List<Object?> get props => [tripId];
}
