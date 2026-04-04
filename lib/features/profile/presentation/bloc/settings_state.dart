import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_state.freezed.dart';

@freezed
sealed class SettingsState with _$SettingsState {
  const factory SettingsState.initial() = SettingsInitial;
  const factory SettingsState.loading() = SettingsLoading;
  const factory SettingsState.loaded({required String displayName}) = SettingsLoaded;
  const factory SettingsState.saving() = SettingsSaving;
  const factory SettingsState.saved({required String displayName}) = SettingsSaved;
  const factory SettingsState.error({required String message}) = SettingsError;
}
