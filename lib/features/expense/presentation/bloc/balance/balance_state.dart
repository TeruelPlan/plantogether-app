import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/entity/balance.dart';

part 'balance_state.freezed.dart';

@freezed
sealed class BalanceState with _$BalanceState {
  const factory BalanceState.initial() = _Initial;
  const factory BalanceState.loading() = _Loading;
  const factory BalanceState.loaded({required Balance balance}) = _Loaded;
  const factory BalanceState.error({required String message}) = _Error;
}
