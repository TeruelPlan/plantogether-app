import '../../domain/model/poll_model.dart';
import '../../domain/repository/poll_repository.dart';
import '../datasource/poll_remote_datasource.dart';

class PollRepositoryImpl implements PollRepository {
  final PollRemoteDatasource _remoteDatasource;

  PollRepositoryImpl(this._remoteDatasource);

  @override
  Future<List<PollModel>> getPollsForTrip(String tripId) async {
    final dtos = await _remoteDatasource.getPollsForTrip(tripId);
    return dtos.map((d) => d.toDomain()).toList();
  }

  @override
  Future<PollModel> createPoll({
    required String tripId,
    required String title,
    required List<SlotInput> slots,
  }) async {
    final dto = await _remoteDatasource.createPoll(
      tripId: tripId,
      title: title,
      slots: slots,
    );
    return dto.toDomain();
  }

  @override
  Future<PollDetailModel> getPollDetail(String pollId) async {
    final dto = await _remoteDatasource.getPollDetail(pollId);
    return dto.toDomain();
  }

  @override
  Future<PollVoteModel> respond({
    required String pollId,
    required String slotId,
    required VoteStatus status,
  }) async {
    final dto = await _remoteDatasource.respond(
      pollId: pollId,
      slotId: slotId,
      status: status,
    );
    return dto.toDomain();
  }
}
