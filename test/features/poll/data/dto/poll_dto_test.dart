import 'package:flutter_test/flutter_test.dart';
import 'package:plantogether_app/features/poll/data/dto/poll_dto.dart';

void main() {
  group('PollDto.toDomain date parsing', () {
    test('parses createdAt Instant and slot LocalDate fields', () {
      final json = <String, dynamic>{
        'id': 'poll-1',
        'tripId': 'trip-1',
        'title': 'When to leave?',
        'status': 'OPEN',
        'createdBy': 'device-1',
        'createdAt': '2026-04-01T09:15:00.000Z',
        'slots': [
          {
            'id': 's1',
            'startDate': '2026-06-01',
            'endDate': '2026-06-07',
            'slotIndex': 0,
          },
          {
            'id': 's2',
            'startDate': '2026-06-15',
            'endDate': '2026-06-21',
            'slotIndex': 1,
          },
        ],
      };

      final model = PollDto.fromJson(json).toDomain();

      expect(model.createdAt, DateTime.utc(2026, 4, 1, 9, 15));
      expect(model.slots, hasLength(2));
      expect(model.slots[0].startDate, DateTime(2026, 6, 1));
      expect(model.slots[0].endDate, DateTime(2026, 6, 7));
      expect(model.slots[1].startDate, DateTime(2026, 6, 15));
      expect(model.slots[1].endDate, DateTime(2026, 6, 21));
    });

    test('handles missing slots list', () {
      final json = <String, dynamic>{
        'id': 'poll-2',
        'tripId': 'trip-1',
        'title': 'Empty',
        'status': 'LOCKED',
        'createdBy': 'device-1',
        'createdAt': '2026-04-01T09:15:00.000Z',
      };

      final model = PollDto.fromJson(json).toDomain();

      expect(model.slots, isEmpty);
      expect(model.createdAt, DateTime.utc(2026, 4, 1, 9, 15));
    });
  });
}
