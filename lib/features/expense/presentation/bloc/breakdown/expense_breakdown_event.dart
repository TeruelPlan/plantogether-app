import 'package:equatable/equatable.dart';

abstract class ExpenseBreakdownEvent extends Equatable {
  const ExpenseBreakdownEvent();

  @override
  List<Object?> get props => [];
}

class LoadBreakdown extends ExpenseBreakdownEvent {
  final String tripId;

  const LoadBreakdown(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

class RefreshBreakdown extends ExpenseBreakdownEvent {
  final String tripId;

  const RefreshBreakdown(this.tripId);

  @override
  List<Object?> get props => [tripId];
}
