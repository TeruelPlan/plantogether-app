import 'package:json_annotation/json_annotation.dart';

import '../../domain/model/comment_model.dart';

part 'comment_dto.g.dart';

@JsonSerializable()
class CommentDto {
  final String id;
  final String destinationId;
  final String authorDeviceId;
  final String authorDisplayName;
  final String content;
  final DateTime createdAt;

  const CommentDto({
    required this.id,
    required this.destinationId,
    required this.authorDeviceId,
    required this.authorDisplayName,
    required this.content,
    required this.createdAt,
  });

  factory CommentDto.fromJson(Map<String, dynamic> json) =>
      _$CommentDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CommentDtoToJson(this);

  CommentModel toDomain() => CommentModel(
        id: id,
        destinationId: destinationId,
        authorDeviceId: authorDeviceId,
        authorDisplayName: authorDisplayName,
        content: content,
        createdAt: createdAt,
      );
}

@JsonSerializable()
class AddCommentRequestDto {
  final String content;

  const AddCommentRequestDto({required this.content});

  factory AddCommentRequestDto.fromJson(Map<String, dynamic> json) =>
      _$AddCommentRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AddCommentRequestDtoToJson(this);
}
