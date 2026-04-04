import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/core/security/device_id_service.dart';
import 'package:plantogether_app/features/profile/presentation/bloc/settings_bloc.dart';
import 'package:plantogether_app/features/profile/presentation/bloc/settings_event.dart';
import 'package:plantogether_app/features/profile/presentation/bloc/settings_state.dart';

class MockDeviceIdService extends Mock implements DeviceIdService {}

void main() {
  group('SettingsBloc', () {
    late SettingsBloc settingsBloc;
    late MockDeviceIdService mockDeviceIdService;

    setUp(() {
      mockDeviceIdService = MockDeviceIdService();
      settingsBloc = SettingsBloc(mockDeviceIdService);
    });

    tearDown(() {
      settingsBloc.close();
    });

    blocTest<SettingsBloc, SettingsState>(
      'emits [loading, loaded] when LoadSettings succeeds',
      build: () {
        when(() => mockDeviceIdService.getDisplayName())
            .thenAnswer((_) async => 'Alice');
        return settingsBloc;
      },
      act: (bloc) => bloc.add(const LoadSettings()),
      expect: () => [
        const SettingsState.loading(),
        const SettingsState.loaded(displayName: 'Alice'),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits [loading, loaded] with empty string when getDisplayName returns null',
      build: () {
        when(() => mockDeviceIdService.getDisplayName())
            .thenAnswer((_) async => null);
        return settingsBloc;
      },
      act: (bloc) => bloc.add(const LoadSettings()),
      expect: () => [
        const SettingsState.loading(),
        const SettingsState.loaded(displayName: ''),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits [saving, saved] when SaveDisplayName succeeds',
      build: () {
        when(() => mockDeviceIdService.setDisplayName('Bob'))
            .thenAnswer((_) async {});
        return settingsBloc;
      },
      act: (bloc) => bloc.add(const SaveDisplayName('Bob')),
      expect: () => [
        const SettingsState.saving(),
        const SettingsState.saved(displayName: 'Bob'),
      ],
      verify: (_) {
        verify(() => mockDeviceIdService.setDisplayName('Bob')).called(1);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits [loading, error] when LoadSettings throws',
      build: () {
        when(() => mockDeviceIdService.getDisplayName())
            .thenThrow(Exception('storage error'));
        return settingsBloc;
      },
      act: (bloc) => bloc.add(const LoadSettings()),
      expect: () => [
        const SettingsState.loading(),
        isA<SettingsError>(),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits [saving, error] when SaveDisplayName throws',
      build: () {
        when(() => mockDeviceIdService.setDisplayName(any()))
            .thenThrow(Exception('write error'));
        return settingsBloc;
      },
      act: (bloc) => bloc.add(const SaveDisplayName('Bob')),
      expect: () => [
        const SettingsState.saving(),
        isA<SettingsError>(),
      ],
    );
  });
}
