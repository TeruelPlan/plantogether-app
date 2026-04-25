import 'package:equatable/equatable.dart';

sealed class DestinationCommentEvent extends Equatable {
  const DestinationCommentEvent();

  @override
  List<Object?> get props => const [];
}

class LoadComments extends DestinationCommentEvent {
  final String destinationId;

  const LoadComments(this.destinationId);

  @override
  List<Object?> get props => [destinationId];
}

class AddComment extends DestinationCommentEvent {
  final String destinationId;
  final String content;

  const AddComment(this.destinationId, this.content);

  @override
  List<Object?> get props => [destinationId, content];
}
