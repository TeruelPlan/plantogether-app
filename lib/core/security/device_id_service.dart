import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class DeviceIdService {
  static const _keyDeviceId = 'device_id';
  static const _keyDisplayName = 'display_name';

  final FlutterSecureStorage _storage;
  Future<String>? _deviceIdFuture;

  DeviceIdService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Returns existing UUID or generates + stores a new UUID v4.
  /// Concurrent calls are safe — all share the same in-flight Future.
  Future<String> getOrCreateDeviceId() {
    return _deviceIdFuture ??= _fetchOrCreateDeviceId();
  }

  Future<String> _fetchOrCreateDeviceId() async {
    String? id = await _storage.read(key: _keyDeviceId);
    if (id == null) {
      id = const Uuid().v4();
      await _storage.write(key: _keyDeviceId, value: id);
    }
    return id;
  }

  Future<String?> getDeviceId() => _storage.read(key: _keyDeviceId);

  Future<String?> getDisplayName() => _storage.read(key: _keyDisplayName);

  Future<void> setDisplayName(String name) =>
      _storage.write(key: _keyDisplayName, value: name);
}
