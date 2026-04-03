import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plantogether_app/features/profile/domain/repository/profile_repository.dart';
import 'package:plantogether_app/features/profile/presentation/bloc/profile_event.dart';
import 'package:plantogether_app/features/profile/presentation/bloc/profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _repository;

  ProfileBloc(this._repository) : super(const ProfileState.initial()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateDisplayName>(_onUpdateDisplayName);
  }

  Future<void> _onLoadProfile(LoadProfile event, Emitter<ProfileState> emit) async {
    emit(const ProfileState.loading());
    try {
      final profile = await _repository.getMyProfile();
      emit(ProfileState.loaded(profile));
    } catch (e) {
      emit(ProfileState.error(e.toString()));
    }
  }

  Future<void> _onUpdateDisplayName(UpdateDisplayName event, Emitter<ProfileState> emit) async {
    emit(const ProfileState.updating());
    try {
      final profile = await _repository.updateMyProfile(event.displayName);
      emit(ProfileState.updateSuccess(profile));
    } catch (e) {
      emit(ProfileState.error(e.toString()));
    }
  }
}
