import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
}

class LoadSettings extends SettingsEvent {
  const LoadSettings();

  @override
  List<Object?> get props => [];
}

class SaveDisplayName extends SettingsEvent {
  final String name;

  const SaveDisplayName(this.name);

  @override
  List<Object?> get props => [name];
}
