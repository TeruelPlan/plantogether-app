import '../../domain/model/destination_model.dart';
import '../../domain/repository/destination_repository.dart';
import '../datasource/destination_remote_datasource.dart';
import '../dto/destination_dto.dart';

class DestinationRepositoryImpl implements DestinationRepository {
  final DestinationRemoteDatasource _remoteDatasource;

  DestinationRepositoryImpl(this._remoteDatasource);

  @override
  Future<List<DestinationModel>> list(String tripId) async {
    final dtos = await _remoteDatasource.list(tripId);
    return dtos.map((d) => d.toDomain()).toList();
  }

  @override
  Future<DestinationModel> propose(
    String tripId,
    ProposeDestinationInput input,
  ) async {
    final body = ProposeDestinationRequestDto(
      name: input.name,
      description: input.description,
      imageKey: input.imageKey,
      estimatedBudget: input.estimatedBudget,
      currency: input.currency,
      externalUrl: input.externalUrl,
    );
    final dto = await _remoteDatasource.propose(tripId, body);
    return dto.toDomain();
  }
}
