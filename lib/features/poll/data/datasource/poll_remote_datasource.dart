import 'package:intl/intl.dart';

import '../../../../core/network/dio_client.dart';
import '../dto/poll_dto.dart';

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
}
