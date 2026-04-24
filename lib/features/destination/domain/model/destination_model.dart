import 'package:freezed_annotation/freezed_annotation.dart';

part 'destination_model.freezed.dart';

@freezed
abstract class DestinationVotesModel with _$DestinationVotesModel {
  const factory DestinationVotesModel({
    @Default(0) int totalVotes,
    @Default({}) Map<String, int> rankVotes,
    @Default(false) bool myVoteCast,
    int? myRank,
  }) = _DestinationVotesModel;
}

@freezed
abstract class DestinationModel with _$DestinationModel {
  const factory DestinationModel({
    required String id,
    required String tripId,
    required String name,
    String? description,
    String? imageKey,
    double? estimatedBudget,
    String? currency,
    String? externalUrl,
    required String proposedByDeviceId,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(DestinationVotesModel()) DestinationVotesModel votes,
  }) = _DestinationModel;
}
