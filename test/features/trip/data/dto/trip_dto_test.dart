import 'package:flutter_test/flutter_test.dart';
import 'package:plantogether_app/features/trip/data/dto/trip_dto.dart';

void main() {
  group('TripDto.toDomain date parsing', () {
    test('parses LocalDate and Instant fields from realistic backend JSON', () {
      final json = <String, dynamic>{
        'id': 'trip-1',
        'title': 'Beach Trip',
        'description': 'Fun',
        'status': 'PLANNING',
        'referenceCurrency': 'EUR',
        'startDate': '2026-06-01',
        'endDate': '2026-06-07',
        'createdBy': 'device-1',
        'createdAt': '2026-04-04T10:30:00.000Z',
        'updatedAt': '2026-04-05T11:00:00.000Z',
        'memberCount': 0,
        'members': <Map<String, dynamic>>[],
      };

      final model = TripDto.fromJson(json).toDomain();

      expect(model.startDate, DateTime(2026, 6, 1));
      expect(model.endDate, DateTime(2026, 6, 7));
      expect(model.createdAt, DateTime.utc(2026, 4, 4, 10, 30));
      expect(model.updatedAt, DateTime.utc(2026, 4, 5, 11));
    });

    test('returns null startDate/endDate when absent', () {
      final json = <String, dynamic>{
        'id': 'trip-2',
        'title': 'No dates yet',
        'status': 'PLANNING',
        'startDate': null,
        'endDate': null,
        'createdBy': 'device-1',
        'createdAt': '2026-04-04T10:30:00.000Z',
        'updatedAt': '2026-04-04T10:30:00.000Z',
      };

      final model = TripDto.fromJson(json).toDomain();

      expect(model.startDate, isNull);
      expect(model.endDate, isNull);
      expect(model.createdAt, DateTime.utc(2026, 4, 4, 10, 30));
    });

    test('parses TripMemberDto.joinedAt as Instant', () {
      final json = <String, dynamic>{
        'id': 'trip-3',
        'title': 'Trip with members',
        'status': 'PLANNING',
        'createdBy': 'device-1',
        'createdAt': '2026-04-04T10:30:00.000Z',
        'updatedAt': '2026-04-04T10:30:00.000Z',
        'members': [
          {
            'id': 'member-1',
            'displayName': 'Alice',
            'role': 'ORGANIZER',
            'joinedAt': '2026-01-01T08:00:00.000Z',
            'isMe': true,
          },
        ],
      };

      final model = TripDto.fromJson(json).toDomain();

      expect(model.members.single.joinedAt, DateTime.utc(2026, 1, 1, 8));
    });
  });
}
