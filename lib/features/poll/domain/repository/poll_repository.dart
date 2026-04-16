import '../../data/datasource/poll_remote_datasource.dart';
import '../model/poll_model.dart';

abstract class PollRepository {
  Future<List<PollModel>> getPollsForTrip(String tripId);

  Future<PollModel> createPoll({
    required String tripId,
    required String title,
    required List<SlotInput> slots,
  });
}
