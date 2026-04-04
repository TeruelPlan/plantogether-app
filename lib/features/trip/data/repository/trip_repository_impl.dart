import '../../domain/model/trip_model.dart';
import '../../domain/repository/trip_repository.dart';
import '../datasource/trip_remote_datasource.dart';

class TripRepositoryImpl implements TripRepository {
  final TripRemoteDatasource _remoteDatasource;

  TripRepositoryImpl(this._remoteDatasource);

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
}
