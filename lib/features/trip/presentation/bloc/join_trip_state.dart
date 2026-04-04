import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/model/trip_model.dart';
import '../../domain/model/trip_preview_model.dart';

part 'join_trip_state.freezed.dart';

@freezed
sealed class JoinTripState with _$JoinTripState {
  const factory JoinTripState.initial() = _Initial;
  const factory JoinTripState.loadingPreview() = _LoadingPreview;
  const factory JoinTripState.previewLoaded(
      {required TripPreviewModel preview}) = _PreviewLoaded;
  const factory JoinTripState.joining() = _Joining;
  const factory JoinTripState.joined({required TripModel trip}) = _Joined;
  const factory JoinTripState.failure({required String message}) = _Failure;
}
