import 'package:equatable/equatable.dart';

import '../model/destination_model.dart';

class ProposeDestinationInput extends Equatable {
  final String name;
  final String? description;
  final String? imageKey;
  final double? estimatedBudget;
  final String? currency;
  final String? externalUrl;

  const ProposeDestinationInput({
    required this.name,
    this.description,
    this.imageKey,
    this.estimatedBudget,
    this.currency,
    this.externalUrl,
  });

  @override
  List<Object?> get props =>
      [name, description, imageKey, estimatedBudget, currency, externalUrl];
}

abstract class DestinationRepository {
  Future<List<DestinationModel>> list(String tripId);

  Future<DestinationModel> propose(
    String tripId,
    ProposeDestinationInput input,
  );
}
