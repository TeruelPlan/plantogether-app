import '../../../../core/network/dio_client.dart';
import '../../domain/model/vote_config_model.dart';
import '../dto/comment_dto.dart';
import '../dto/destination_dto.dart';
import '../dto/vote_config_dto.dart';
import '../dto/vote_dto.dart';

class DestinationRemoteDatasource {
  final DioClient _dioClient;

  DestinationRemoteDatasource(this._dioClient);

  Future<List<DestinationDto>> list(String tripId) async {
    final response = await _dioClient.dio.get('/api/v1/trips/$tripId/destinations');
    return (response.data as List)
        .map((json) => DestinationDto.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<DestinationDto> propose(
    String tripId,
    ProposeDestinationRequestDto body,
  ) async {
    final response = await _dioClient.dio.post(
      '/api/v1/trips/$tripId/destinations',
      data: body.toJson(),
    );
    return DestinationDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<VoteConfigDto> getVoteConfig(String tripId) async {
    final response = await _dioClient.dio
        .get('/api/v1/trips/$tripId/destinations/vote-config');
    return VoteConfigDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<VoteConfigDto> putVoteConfig(String tripId, VoteMode mode) async {
    final body = VoteConfigRequestDto(mode: mode);
    final response = await _dioClient.dio.put(
      '/api/v1/trips/$tripId/destinations/vote-config',
      data: body.toJson(),
    );
    return VoteConfigDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<VoteResponseDto> castVote(String destinationId, {int? rank}) async {
    final body = CastVoteRequestDto(rank: rank);
    final response = await _dioClient.dio.post(
      '/api/v1/destinations/$destinationId/vote',
      data: body.toJson(),
    );
    return VoteResponseDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> retractVote(String destinationId) async {
    await _dioClient.dio.delete('/api/v1/destinations/$destinationId/vote');
  }

  Future<DestinationDto> selectDestination(String destinationId) async {
    final response = await _dioClient.dio.patch(
      '/api/v1/destinations/$destinationId/select',
    );
    return DestinationDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CommentDto> addComment(String destinationId, String content) async {
    final response = await _dioClient.dio.post(
      '/api/v1/destinations/$destinationId/comments',
      data: AddCommentRequestDto(content: content).toJson(),
    );
    return CommentDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<CommentDto>> listComments(String destinationId) async {
    final response = await _dioClient.dio
        .get('/api/v1/destinations/$destinationId/comments');
    return (response.data as List)
        .map((json) => CommentDto.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
