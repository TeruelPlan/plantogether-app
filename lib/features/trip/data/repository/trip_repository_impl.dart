import '../../domain/model/trip_invitation_model.dart';
import '../../domain/model/trip_model.dart';
import '../../domain/model/trip_preview_model.dart';
import '../../domain/repository/trip_repository.dart';
import '../datasource/trip_remote_datasource.dart';

class TripRepositoryImpl implements TripRepository {
  final TripRemoteDatasource _remoteDatasource;

  TripRepositoryImpl(this._remoteDatasource);

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
  Future<TripInvitationModel> getInvitation(String tripId) async {
    final dto = await _remoteDatasource.getInvitation(tripId);
    return dto.toDomain();
  }

  @override
  Future<TripPreviewModel> getTripPreview(String tripId, String token) async {
    final dto = await _remoteDatasource.getTripPreview(tripId, token);
    return dto.toDomain();
  }

  @override
  Future<TripModel> joinTrip(String tripId, String token) async {
    final dto = await _remoteDatasource.joinTrip(tripId, token);
    return dto.toDomain();
  }
}
