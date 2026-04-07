import '../model/trip_invitation_model.dart';
import '../model/trip_member_model.dart';
import '../model/trip_model.dart';
import '../model/trip_preview_model.dart';

abstract class TripRepository {
  Future<List<TripModel>> listTrips();

  Future<TripModel> getTrip(String tripId);

  Future<TripModel> createTrip({
    required String title,
    String? description,
    String? currency,
  });

  Future<TripModel> updateTrip(
    String tripId, {
    required String title,
    String? description,
    String? currency,
  });

  Future<TripModel> archiveTrip(String tripId);

  Future<TripInvitationModel> getInvitation(String tripId);

  Future<TripPreviewModel> getTripPreview(String tripId, String token);

  Future<TripModel> joinTrip(String tripId, String token);

  Future<List<TripMemberModel>> getMembers(String tripId);

  Future<void> removeMember(String tripId, String deviceId);
}
