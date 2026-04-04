import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/model/trip_model.dart';

part 'create_trip_state.freezed.dart';

@freezed
sealed class CreateTripState with _$CreateTripState {
  const factory CreateTripState.initial() = _Initial;
  const factory CreateTripState.loading() = _Loading;
  const factory CreateTripState.success({required TripModel trip}) = _Success;
  const factory CreateTripState.failure({required String message}) = _Failure;
}
