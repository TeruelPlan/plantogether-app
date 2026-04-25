import 'package:equatable/equatable.dart';

import '../model/comment_model.dart';
import '../model/destination_model.dart';
import '../model/vote_config_model.dart';

class ProposeDestinationInput extends Equatable {
  final String name;
  final String? description;
  final String? imageKey;
  final double? estimatedBudget;
  final String? currency;
  final String? externalUrl;

  const ProposeDestinationInput({
    required this.name,
    this.description,
    this.imageKey,
    this.estimatedBudget,
    this.currency,
    this.externalUrl,
  });

  @override
  List<Object?> get props =>
      [name, description, imageKey, estimatedBudget, currency, externalUrl];
}

abstract class DestinationRepository {
  Future<List<DestinationModel>> list(String tripId);

  Future<DestinationModel> propose(
    String tripId,
    ProposeDestinationInput input,
  );

  Future<VoteConfigModel> getVoteConfig(String tripId);

  Future<VoteConfigModel> updateVoteConfig(String tripId, VoteMode mode);

  Future<void> castVote(String destinationId, {int? rank});

  Future<void> retractVote(String destinationId);

  Future<DestinationModel> selectDestination(String destinationId);

  Future<CommentModel> addComment({
    required String destinationId,
    required String content,
  });

  Future<List<CommentModel>> listComments(String destinationId);
}
