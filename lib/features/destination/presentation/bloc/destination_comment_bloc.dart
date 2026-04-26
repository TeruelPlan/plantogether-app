import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/model/comment_model.dart';
import '../../domain/repository/destination_repository.dart';
import 'destination_comment_event.dart';
import 'destination_comment_state.dart';

class DestinationCommentBloc
    extends Bloc<DestinationCommentEvent, DestinationCommentState> {
  final DestinationRepository _repository;
  final String? _myDeviceId;
  final String? _myDisplayName;

  DestinationCommentBloc(
    this._repository, {
    String? myDeviceId,
    String? myDisplayName,
  })  : _myDeviceId = myDeviceId,
        _myDisplayName = myDisplayName,
        super(const DestinationCommentState.initial()) {
    on<LoadComments>(_onLoad, transformer: droppable());
    on<AddComment>(_onAdd, transformer: sequential());
  }

  Future<void> _onLoad(
    LoadComments event,
    Emitter<DestinationCommentState> emit,
  ) async {
    final hasData = state.maybeWhen(
      loaded: (_, _, _) => true,
      orElse: () => false,
    );
    final pendingSubmitError = state.maybeWhen(
      loaded: (_, _, submitError) => submitError,
      orElse: () => null,
    );
    if (!hasData) {
      emit(const DestinationCommentState.loading());
    }
    try {
      final comments = await _repository.listComments(event.destinationId);
      emit(DestinationCommentState.loaded(
        comments: comments,
        submitError: pendingSubmitError,
      ));
    } on DioException catch (e) {
      emit(DestinationCommentState.error(message: _friendlyMessage(e)));
    } catch (_) {
      emit(const DestinationCommentState.error(
          message: 'Something went wrong. Please try again.'));
    }
  }

  Future<void> _onAdd(
    AddComment event,
    Emitter<DestinationCommentState> emit,
  ) async {
    final trimmed = event.content.trim();
    if (trimmed.isEmpty || trimmed.length > 2000) {
      final previous = state.maybeWhen(
        loaded: (comments, _, _) => comments,
        orElse: () => <CommentModel>[],
      );
      emit(DestinationCommentState.loaded(
        comments: previous,
        submitError: trimmed.isEmpty
            ? 'Comment cannot be empty'
            : 'Comment must be at most 2000 characters',
      ));
      return;
    }

    final previous = state.maybeWhen(
      loaded: (comments, _, _) => comments,
      orElse: () => <CommentModel>[],
    );

    final tempId = 'pending-${DateTime.now().microsecondsSinceEpoch}';
    final pending = CommentModel(
      id: tempId,
      destinationId: event.destinationId,
      authorDeviceId: _myDeviceId ?? 'me',
      authorDisplayName: _myDisplayName ?? 'You',
      content: trimmed,
      createdAt: DateTime.now().toUtc(),
      pending: true,
    );
    final optimistic = [...previous, pending];

    emit(DestinationCommentState.loaded(
      comments: optimistic,
      submitting: true,
    ));

    try {
      final saved = await _repository.addComment(
        destinationId: event.destinationId,
        content: trimmed,
      );
      final reconciled = [
        for (final c in optimistic) c.id == tempId ? saved : c,
      ];
      emit(DestinationCommentState.loaded(comments: reconciled));
    } on DioException catch (e) {
      emit(DestinationCommentState.loaded(
        comments: previous,
        submitError: _submitError(e),
      ));
    } catch (_) {
      emit(DestinationCommentState.loaded(
        comments: previous,
        submitError: 'Failed to send comment',
      ));
    }
  }

  String _friendlyMessage(DioException e) {
    final status = e.response?.statusCode;
    if (status == 403) return 'You are not a member of this trip.';
    if (status == 404) return 'Destination no longer exists.';
    if (status != null && status >= 500) {
      return 'Server unavailable. Please try again later.';
    }
    return 'Network error. Please check your connection.';
  }

  String _submitError(DioException e) {
    final status = e.response?.statusCode;
    if (status == 400) return 'Please enter a valid comment.';
    if (status == 403) return 'You are not a member of this trip.';
    return 'Failed to send comment';
  }
}

