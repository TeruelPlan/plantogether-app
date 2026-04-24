import 'package:freezed_annotation/freezed_annotation.dart';

part 'vote_config_model.freezed.dart';

/// Vote mode for a trip's destination polling.
///
/// Serialized to/from the backend as uppercase wire values
/// (`SIMPLE`, `APPROVAL`, `RANKING`).
enum VoteMode {
  simple,
  approval,
  ranking;

  String toWire() {
    switch (this) {
      case VoteMode.simple:
        return 'SIMPLE';
      case VoteMode.approval:
        return 'APPROVAL';
      case VoteMode.ranking:
        return 'RANKING';
    }
  }

  /// Parses a server wire value into a [VoteMode]. Falls back to
  /// [VoteMode.simple] for unknown values so older clients keep working
  /// when the server introduces a new mode.
  static VoteMode fromWire(String raw) {
    switch (raw.toUpperCase()) {
      case 'SIMPLE':
        return VoteMode.simple;
      case 'APPROVAL':
        return VoteMode.approval;
      case 'RANKING':
        return VoteMode.ranking;
      default:
        return VoteMode.simple;
    }
  }
}

@freezed
abstract class VoteConfigModel with _$VoteConfigModel {
  const factory VoteConfigModel({
    required String tripId,
    required VoteMode mode,
    required DateTime updatedAt,
  }) = _VoteConfigModel;
}
