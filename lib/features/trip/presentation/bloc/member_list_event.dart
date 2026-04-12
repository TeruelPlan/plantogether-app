import 'package:equatable/equatable.dart';

abstract class MemberListEvent extends Equatable {
  const MemberListEvent();

  @override
  List<Object?> get props => [];
}

class LoadMembers extends MemberListEvent {
  final String tripId;

  const LoadMembers(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

class RemoveMember extends MemberListEvent {
  final String tripId;
  final String memberId;

  const RemoveMember({required this.tripId, required this.memberId});

  @override
  List<Object?> get props => [tripId, memberId];
}
