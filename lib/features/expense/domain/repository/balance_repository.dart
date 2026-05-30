import '../entity/balance.dart';

abstract class BalanceRepository {
  Future<Balance> getBalance(String tripId);

  /// Marks a settlement transfer as done. Identity is the per-trip member id.
  Future<void> markTransferDone(String tripId, SettlementTransfer transfer);
}
