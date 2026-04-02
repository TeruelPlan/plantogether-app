import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/core/security/device_id_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late DeviceIdService sut;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    sut = DeviceIdService(storage: mockStorage);
  });

  group('getOrCreateDeviceId', () {
    test('generates and persists UUID when no id stored', () async {
      when(() => mockStorage.read(key: 'device_id'))
          .thenAnswer((_) async => null);
      when(() => mockStorage.write(
            key: 'device_id',
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      final id = await sut.getOrCreateDeviceId();

      expect(id, isNotEmpty);
      // UUID v4 format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
      expect(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ).hasMatch(id),
        isTrue,
      );
      verify(() => mockStorage.write(key: 'device_id', value: id)).called(1);
    });

    test('returns stored UUID without generating a new one', () async {
      const storedId = 'existing-uuid-value';
      when(() => mockStorage.read(key: 'device_id'))
          .thenAnswer((_) async => storedId);

      final id = await sut.getOrCreateDeviceId();

      expect(id, equals(storedId));
      verifyNever(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ));
    });

    test('returns same UUID on consecutive calls', () async {
      var callCount = 0;
      when(() => mockStorage.read(key: 'device_id')).thenAnswer((_) async {
        callCount++;
        return callCount == 1 ? null : 'generated-uuid';
      });
      when(() => mockStorage.write(
            key: 'device_id',
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      final first = await sut.getOrCreateDeviceId();

      when(() => mockStorage.read(key: 'device_id'))
          .thenAnswer((_) async => first);

      final second = await sut.getOrCreateDeviceId();

      expect(first, equals(second));
    });
  });

  group('getDeviceId', () {
    test('returns stored device id', () async {
      const storedId = 'some-device-id';
      when(() => mockStorage.read(key: 'device_id'))
          .thenAnswer((_) async => storedId);

      final id = await sut.getDeviceId();
      expect(id, equals(storedId));
    });

    test('returns null when no device id stored', () async {
      when(() => mockStorage.read(key: 'device_id'))
          .thenAnswer((_) async => null);

      final id = await sut.getDeviceId();
      expect(id, isNull);
    });
  });

  group('setDisplayName / getDisplayName', () {
    test('round-trip stores and retrieves display name', () async {
      const name = 'Alice';
      when(() => mockStorage.write(key: 'display_name', value: name))
          .thenAnswer((_) async {});
      when(() => mockStorage.read(key: 'display_name'))
          .thenAnswer((_) async => name);

      await sut.setDisplayName(name);
      final retrieved = await sut.getDisplayName();

      expect(retrieved, equals(name));
      verify(() => mockStorage.write(key: 'display_name', value: name))
          .called(1);
    });

    test('getDisplayName returns null when not set', () async {
      when(() => mockStorage.read(key: 'display_name'))
          .thenAnswer((_) async => null);

      final name = await sut.getDisplayName();
      expect(name, isNull);
    });
  });
}
