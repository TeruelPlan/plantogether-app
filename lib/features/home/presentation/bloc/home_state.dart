import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../trip/domain/model/trip_model.dart';

part 'home_state.freezed.dart';

@freezed
sealed class HomeState with _$HomeState {
  const factory HomeState.initial() = _Initial;
  const factory HomeState.loading() = _Loading;
  const factory HomeState.loaded({required List<TripModel> trips}) = _Loaded;
  const factory HomeState.failure({required String message}) = _Failure;
}
