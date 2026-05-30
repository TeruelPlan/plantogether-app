import 'package:freezed_annotation/freezed_annotation.dart';

part 'balance.freezed.dart';

/// Status of a settlement transfer. PENDING until a member marks it done
/// (story 5.4.2); DONE once persisted server-side.
enum SettlementStatus {
  pending,
  done;

  static SettlementStatus fromWire(String? s) {
    switch ((s ?? 'PENDING').toUpperCase()) {
      case 'DONE':
        return SettlementStatus.done;
      case 'PENDING':
      default:
        return SettlementStatus.pending;
    }
  }
}

/// A single minimal transfer from a debtor member to a creditor member, in the
/// trip reference currency. Identity is the per-trip member id.
@freezed
sealed class SettlementTransfer with _$SettlementTransfer {
  const factory SettlementTransfer({
    required String fromMemberId,
    required String toMemberId,
    required double amount,
    required String currency,
    @Default(SettlementStatus.pending) SettlementStatus status,
    DateTime? settledAt,
    String? settledByMemberId,
  }) = _SettlementTransfer;
}

/// Trip-wide settlement snapshot. The same plan is shown to every member;
/// "my turn" highlighting is derived client-side from the current member id.
@freezed
sealed class Balance with _$Balance {
  const factory Balance({
    required String tripId,
    required String referenceCurrency,
    required Map<String, double> participantBalances,
    required List<SettlementTransfer> settlements,
    @Default(false) bool allSettled,
    DateTime? computedAt,
  }) = _Balance;
}
