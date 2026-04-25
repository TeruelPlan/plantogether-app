import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/model/destination_model.dart';
import '../../domain/model/vote_config_model.dart';

part 'destination_state.freezed.dart';

@freezed
sealed class DestinationState with _$DestinationState {
  const factory DestinationState.initial() = _Initial;
  const factory DestinationState.loading() = _Loading;
  const factory DestinationState.loaded({
    required List<DestinationModel> destinations,
    VoteMode? mode,
    String? myDeviceId,
    String? connectionBanner,
    String? transientError,
  }) = _Loaded;
  const factory DestinationState.error({required String message}) = _Error;
}

extension DestinationStateChosenX on DestinationState {
  DestinationModel? get chosenDestination => maybeWhen(
        loaded: (destinations, _, __, ___, ____) {
          for (final d in destinations) {
            if (d.status == DestinationStatus.chosen) return d;
          }
          return null;
        },
        orElse: () => null,
      );
}
