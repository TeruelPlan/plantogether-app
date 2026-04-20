import 'package:equatable/equatable.dart';

import '../../../../core/network/stomp_client_manager.dart';
import '../../domain/model/poll_model.dart';

abstract class PollDetailEvent extends Equatable {
  const PollDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadPollDetail extends PollDetailEvent {
  final String pollId;

  const LoadPollDetail(this.pollId);

  @override
  List<Object?> get props => [pollId];
}

class CastVote extends PollDetailEvent {
  final String slotId;
  final VoteStatus status;

  const CastVote({required this.slotId, required this.status});

  @override
  List<Object?> get props => [slotId, status];
}

class TripUpdateReceived extends PollDetailEvent {
  final Map<String, dynamic> payload;

  const TripUpdateReceived(this.payload);

  @override
  List<Object?> get props => [payload];
}

class LockPoll extends PollDetailEvent {
  final String slotId;

  const LockPoll(this.slotId);

  @override
  List<Object?> get props => [slotId];
}

class ConnectionStateChanged extends PollDetailEvent {
  final StompConnectionState connectionState;

  const ConnectionStateChanged(this.connectionState);

  @override
  List<Object?> get props => [connectionState];
}

class SuccessBannerConsumed extends PollDetailEvent {
  const SuccessBannerConsumed();
}

class ErrorBannerConsumed extends PollDetailEvent {
  const ErrorBannerConsumed();
}
