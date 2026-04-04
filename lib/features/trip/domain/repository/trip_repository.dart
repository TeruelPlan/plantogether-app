import '../model/trip_invitation_model.dart';
import '../model/trip_model.dart';
import '../model/trip_preview_model.dart';

abstract class TripRepository {
  Future<TripModel> createTrip({
    required String title,
    String? description,
    String? currency,
  });

  Future<TripInvitationModel> getInvitation(String tripId);

  Future<TripPreviewModel> getTripPreview(String tripId, String token);

  Future<TripModel> joinTrip(String tripId, String token);
}
