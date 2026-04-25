import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/model/comment_model.dart';

part 'destination_comment_state.freezed.dart';

@freezed
abstract class DestinationCommentState with _$DestinationCommentState {
  const factory DestinationCommentState.initial() = _Initial;
  const factory DestinationCommentState.loading() = _Loading;
  const factory DestinationCommentState.loaded({
    required List<CommentModel> comments,
    @Default(false) bool submitting,
    String? submitError,
  }) = _Loaded;
  const factory DestinationCommentState.error({required String message}) =
      _Error;
}
