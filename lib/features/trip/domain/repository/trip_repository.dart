import '../model/trip_model.dart';

abstract class TripRepository {
  Future<TripModel> createTrip({
    required String title,
    String? description,
    String? currency,
  });
}
