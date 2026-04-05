import '../model/trip_model.dart';

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
}
