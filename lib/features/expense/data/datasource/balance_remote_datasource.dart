import '../../../../core/network/dio_client.dart';
import '../model/balance_dto.dart';

class BalanceRemoteDatasource {
  final DioClient _dioClient;

  BalanceRemoteDatasource(this._dioClient);

  Future<BalanceDto> getBalance(String tripId) async {
    final response = await _dioClient.dio.get('/api/v1/trips/$tripId/balance');
    return BalanceDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> markTransferDone(
    String tripId,
    MarkTransferDoneRequestDto body,
  ) async {
    await _dioClient.dio.patch(
      '/api/v1/trips/$tripId/balance/settlements',
      data: body.toJson(),
    );
  }
}
