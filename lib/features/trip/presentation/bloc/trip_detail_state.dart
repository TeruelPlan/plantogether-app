import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/model/trip_model.dart';

part 'trip_detail_state.freezed.dart';

@freezed
sealed class TripDetailState with _$TripDetailState {
  const factory TripDetailState.initial() = _Initial;
  const factory TripDetailState.loading() = _Loading;
  const factory TripDetailState.loaded({required TripModel trip}) = _Loaded;
  const factory TripDetailState.failure({required String message}) = _Failure;
}
