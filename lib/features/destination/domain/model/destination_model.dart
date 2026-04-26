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

enum DestinationStatus {
  proposed,
  chosen;

  static DestinationStatus fromWire(String? wire) {
    if (wire == null) return DestinationStatus.proposed;
    switch (wire.toUpperCase()) {
      case 'CHOSEN':
        return DestinationStatus.chosen;
      case 'PROPOSED':
      default:
        return DestinationStatus.proposed;
    }
  }

  String toWire() => switch (this) {
        DestinationStatus.proposed => 'PROPOSED',
        DestinationStatus.chosen => 'CHOSEN',
      };
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
    @Default(DestinationStatus.proposed) DestinationStatus status,
    DateTime? chosenAt,
    String? chosenByDeviceId,
    @Default(DestinationVotesModel()) DestinationVotesModel votes,
  }) = _DestinationModel;
}
