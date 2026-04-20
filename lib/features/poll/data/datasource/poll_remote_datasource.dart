import 'package:intl/intl.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/model/poll_model.dart';
import '../dto/poll_detail_dto.dart';
import '../dto/respond_request_dto.dart';
import '../dto/poll_dto.dart';
import '../dto/vote_response_dto.dart';

class SlotInput {
  final DateTime startDate;
  final DateTime endDate;

  const SlotInput({required this.startDate, required this.endDate});
}

class PollRemoteDatasource {
  final DioClient _dioClient;
  static final DateFormat _isoDate = DateFormat('yyyy-MM-dd');

  PollRemoteDatasource(this._dioClient);

  Future<List<PollDto>> getPollsForTrip(String tripId) async {
    final response = await _dioClient.dio.get('/api/v1/trips/$tripId/polls');
    return (response.data as List)
        .map((json) => PollDto.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<PollDto> createPoll({
    required String tripId,
    required String title,
    required List<SlotInput> slots,
  }) async {
    final response = await _dioClient.dio.post(
      '/api/v1/trips/$tripId/polls',
      data: {
        'title': title,
        'slots': slots
            .map((s) => {
                  'startDate': _isoDate.format(s.startDate),
                  'endDate': _isoDate.format(s.endDate),
                })
            .toList(),
      },
    );
    return PollDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PollDetailDto> getPollDetail(String pollId) async {
    final response = await _dioClient.dio.get('/api/v1/polls/$pollId');
    return PollDetailDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<VoteResponseDto> respond({
    required String pollId,
    required String slotId,
    required VoteStatus status,
  }) async {
    final body = RespondRequestDto.from(slotId: slotId, status: status).toJson();
    final response = await _dioClient.dio.put(
      '/api/v1/polls/$pollId/respond',
      data: body,
    );
    return VoteResponseDto.fromJson(response.data as Map<String, dynamic>);
  }
}
