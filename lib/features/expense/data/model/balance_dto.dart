import 'package:json_annotation/json_annotation.dart';

import '../../domain/entity/balance.dart';

part 'balance_dto.g.dart';

@JsonSerializable()
class SettlementTransferDto {
  final String fromMemberId;
  final String toMemberId;
  final double amount;
  final String currency;
  final String? status;
  final DateTime? settledAt;
  final String? settledByMemberId;

  const SettlementTransferDto({
    required this.fromMemberId,
    required this.toMemberId,
    required this.amount,
    required this.currency,
    this.status,
    this.settledAt,
    this.settledByMemberId,
  });

  factory SettlementTransferDto.fromJson(Map<String, dynamic> json) =>
      _$SettlementTransferDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SettlementTransferDtoToJson(this);

  SettlementTransfer toDomain() => SettlementTransfer(
        fromMemberId: fromMemberId,
        toMemberId: toMemberId,
        amount: amount,
        currency: currency,
        status: SettlementStatus.fromWire(status),
        settledAt: settledAt,
        settledByMemberId: settledByMemberId,
      );
}

@JsonSerializable()
class BalanceDto {
  final String tripId;
  final String referenceCurrency;
  final Map<String, double> participantBalances;
  final List<SettlementTransferDto> settlements;
  final bool? allSettled;
  final DateTime? computedAt;

  const BalanceDto({
    required this.tripId,
    required this.referenceCurrency,
    required this.participantBalances,
    required this.settlements,
    this.allSettled,
    this.computedAt,
  });

  factory BalanceDto.fromJson(Map<String, dynamic> json) =>
      _$BalanceDtoFromJson(json);

  Map<String, dynamic> toJson() => _$BalanceDtoToJson(this);

  Balance toDomain() => Balance(
        tripId: tripId,
        referenceCurrency: referenceCurrency,
        participantBalances: participantBalances,
        settlements: settlements.map((s) => s.toDomain()).toList(),
        allSettled: allSettled ?? false,
        computedAt: computedAt,
      );
}

@JsonSerializable(includeIfNull: false)
class MarkTransferDoneRequestDto {
  final String fromMemberId;
  final String toMemberId;
  final double amount;
  final String currency;

  const MarkTransferDoneRequestDto({
    required this.fromMemberId,
    required this.toMemberId,
    required this.amount,
    required this.currency,
  });

  factory MarkTransferDoneRequestDto.fromJson(Map<String, dynamic> json) =>
      _$MarkTransferDoneRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MarkTransferDoneRequestDtoToJson(this);
}
