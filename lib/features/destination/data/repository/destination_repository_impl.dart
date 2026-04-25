import '../../domain/model/comment_model.dart';
import '../../domain/model/destination_model.dart';
import '../../domain/model/vote_config_model.dart';
import '../../domain/repository/destination_repository.dart';
import '../datasource/destination_remote_datasource.dart';
import '../dto/destination_dto.dart';

class DestinationRepositoryImpl implements DestinationRepository {
  final DestinationRemoteDatasource _remoteDatasource;

  DestinationRepositoryImpl(this._remoteDatasource);

  @override
  Future<List<DestinationModel>> list(String tripId) async {
    final dtos = await _remoteDatasource.list(tripId);
    return dtos.map((d) => d.toDomain()).toList();
  }

  @override
  Future<DestinationModel> propose(
    String tripId,
    ProposeDestinationInput input,
  ) async {
    final body = ProposeDestinationRequestDto(
      name: input.name,
      description: input.description,
      imageKey: input.imageKey,
      estimatedBudget: input.estimatedBudget,
      currency: input.currency,
      externalUrl: input.externalUrl,
    );
    final dto = await _remoteDatasource.propose(tripId, body);
    return dto.toDomain();
  }

  @override
  Future<VoteConfigModel> getVoteConfig(String tripId) async {
    final dto = await _remoteDatasource.getVoteConfig(tripId);
    return dto.toDomain();
  }

  @override
  Future<VoteConfigModel> updateVoteConfig(String tripId, VoteMode mode) async {
    final dto = await _remoteDatasource.putVoteConfig(tripId, mode);
    return dto.toDomain();
  }

  @override
  Future<void> castVote(String destinationId, {int? rank}) {
    return _remoteDatasource.castVote(destinationId, rank: rank);
  }

  @override
  Future<void> retractVote(String destinationId) {
    return _remoteDatasource.retractVote(destinationId);
  }

  @override
  Future<CommentModel> addComment({
    required String destinationId,
    required String content,
  }) async {
    final dto = await _remoteDatasource.addComment(destinationId, content);
    return dto.toDomain();
  }

  @override
  Future<List<CommentModel>> listComments(String destinationId) async {
    final dtos = await _remoteDatasource.listComments(destinationId);
    return dtos.map((d) => d.toDomain()).toList();
  }
}
