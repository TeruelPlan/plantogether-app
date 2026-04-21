import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/model/poll_model.dart';

part 'poll_detail_state.freezed.dart';

@freezed
sealed class PollDetailState with _$PollDetailState {
  const factory PollDetailState.initial() = _Initial;
  const factory PollDetailState.loading() = _Loading;
  const factory PollDetailState.loaded({
    required PollDetailModel detail,
    required String myDeviceId,
    String? errorBanner,
    String? connectionBanner,
    String? successBanner,
    @Default(false) bool locking,
  }) = _Loaded;
  const factory PollDetailState.error({required String message}) = _Error;
}
