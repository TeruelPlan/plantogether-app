import 'package:dio/dio.dart';

import '../../domain/entity/balance.dart';
import '../../domain/repository/balance_repository.dart';
import '../datasource/balance_remote_datasource.dart';
import '../model/balance_dto.dart';

class BalanceRepositoryImpl implements BalanceRepository {
  final BalanceRemoteDatasource _remoteDatasource;

  BalanceRepositoryImpl(this._remoteDatasource);

  @override
  Future<Balance> getBalance(String tripId) async {
    try {
      final dto = await _remoteDatasource.getBalance(tripId);
      return dto.toDomain();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<void> markTransferDone(
    String tripId,
    SettlementTransfer transfer,
  ) async {
    try {
      await _remoteDatasource.markTransferDone(
        tripId,
        MarkTransferDoneRequestDto(
          fromMemberId: transfer.fromMemberId,
          toMemberId: transfer.toMemberId,
          amount: transfer.amount,
          currency: transfer.currency,
        ),
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Exception _mapError(DioException e) {
    final statusCode = e.response?.statusCode;
    if (statusCode == 403) {
      return Exception('You are not a member of this trip');
    }
    if (statusCode == 409) {
      return Exception('The settlement plan changed. Please refresh');
    }
    if (statusCode != null && statusCode >= 500) {
      return Exception('Server error. Please try again later');
    }
    return Exception('Network error. Please check your connection');
  }
}
