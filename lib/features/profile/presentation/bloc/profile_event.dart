import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object> get props => [];
}

class LoadProfile extends ProfileEvent {
  const LoadProfile();
}

class UpdateDisplayName extends ProfileEvent {
  final String displayName;

  const UpdateDisplayName(this.displayName);

  @override
  List<Object> get props => [displayName];
}
