import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plantogether_app/core/security/device_id_service.dart';
import 'package:plantogether_app/features/profile/presentation/bloc/settings_event.dart';
import 'package:plantogether_app/features/profile/presentation/bloc/settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final DeviceIdService _deviceIdService;

  SettingsBloc(this._deviceIdService) : super(const SettingsState.initial()) {
    on<LoadSettings>(_onLoadSettings);
    on<SaveDisplayName>(_onSaveDisplayName);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsState.loading());
    try {
      final name = await _deviceIdService.getDisplayName();
      emit(SettingsState.loaded(displayName: name ?? ''));
    } catch (e) {
      emit(SettingsState.error(message: e.toString()));
    }
  }

  Future<void> _onSaveDisplayName(
    SaveDisplayName event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsState.saving());
    try {
      await _deviceIdService.setDisplayName(event.name);
      emit(SettingsState.saved(displayName: event.name));
    } catch (e) {
      emit(SettingsState.error(message: e.toString()));
    }
  }
}
