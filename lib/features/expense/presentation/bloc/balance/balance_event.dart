import 'package:equatable/equatable.dart';

import '../../../domain/entity/balance.dart';

abstract class BalanceEvent extends Equatable {
  const BalanceEvent();

  @override
  List<Object?> get props => [];
}

class LoadBalance extends BalanceEvent {
  final String tripId;

  const LoadBalance(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

/// Story 5.4.2 — mark a transfer as done (optimistic, reloads on success).
class MarkTransferDone extends BalanceEvent {
  final String tripId;
  final SettlementTransfer transfer;

  const MarkTransferDone({required this.tripId, required this.transfer});

  @override
  List<Object?> get props => [
        tripId,
        transfer.fromMemberId,
        transfer.toMemberId,
        transfer.amount,
        transfer.currency,
      ];
}
