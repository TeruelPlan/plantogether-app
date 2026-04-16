import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/model/poll_model.dart';

part 'poll_state.freezed.dart';

@freezed
sealed class PollState with _$PollState {
  const factory PollState.initial() = _Initial;
  const factory PollState.loading() = _Loading;
  const factory PollState.loaded({required List<PollModel> polls}) = _Loaded;
  const factory PollState.error({required String message}) = _Error;
}
