import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment_model.freezed.dart';

@freezed
abstract class CommentModel with _$CommentModel {
  const factory CommentModel({
    required String id,
    required String destinationId,
    required String authorDeviceId,
    required String authorDisplayName,
    required String content,
    required DateTime createdAt,
    @Default(false) bool pending,
  }) = _CommentModel;
}
