import '../../../../core/data/page_dto.dart';
import '../../../../core/network/dio_client.dart';
import '../model/expense_dto.dart';

class ExpenseRemoteDatasource {
  final DioClient _dioClient;

  ExpenseRemoteDatasource(this._dioClient);

  Future<ExpenseDto> record(String tripId, RecordExpenseRequestDto body) async {
    final response = await _dioClient.dio.post(
      '/api/v1/trips/$tripId/expenses',
      data: body.toJson(),
    );
    return ExpenseDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PageDto<ExpenseDto>> list(
    String tripId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _dioClient.dio.get(
      '/api/v1/trips/$tripId/expenses',
      queryParameters: {
        'page': page,
        'size': size,
        'sort': 'createdAt,desc',
      },
    );
    return PageDto<ExpenseDto>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => ExpenseDto.fromJson(json! as Map<String, dynamic>),
    );
  }
}
