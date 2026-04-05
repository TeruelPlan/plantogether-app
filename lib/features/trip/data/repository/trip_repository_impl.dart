import '../../domain/model/trip_model.dart';
import '../../domain/repository/trip_repository.dart';
import '../datasource/trip_remote_datasource.dart';

class TripRepositoryImpl implements TripRepository {
  final TripRemoteDatasource _remoteDatasource;

  TripRepositoryImpl(this._remoteDatasource);

  @override
  Future<List<TripModel>> listTrips() async {
    final dtos = await _remoteDatasource.listTrips();
    return dtos.map((dto) => dto.toDomain()).toList();
  }

  @override
  Future<TripModel> getTrip(String tripId) async {
    final dto = await _remoteDatasource.getTrip(tripId);
    return dto.toDomain();
  }

  @override
  Future<TripModel> createTrip({
    required String title,
    String? description,
    String? currency,
  }) async {
    final dto = await _remoteDatasource.createTrip(
      title: title,
      description: description,
      currency: currency,
    );
    return dto.toDomain();
  }

  @override
  Future<TripModel> updateTrip(
    String tripId, {
    required String title,
    String? description,
    String? currency,
  }) async {
    final dto = await _remoteDatasource.updateTrip(
      tripId,
      title: title,
      description: description,
      currency: currency,
    );
    return dto.toDomain();
  }

  @override
  Future<TripModel> archiveTrip(String tripId) async {
    final dto = await _remoteDatasource.archiveTrip(tripId);
    return dto.toDomain();
  }
}
