import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/destination/domain/model/comment_model.dart';
import 'package:plantogether_app/features/destination/domain/repository/destination_repository.dart';
import 'package:plantogether_app/features/destination/presentation/bloc/destination_comment_bloc.dart';
import 'package:plantogether_app/features/destination/presentation/bloc/destination_comment_event.dart';
import 'package:plantogether_app/features/destination/presentation/bloc/destination_comment_state.dart';

class MockDestinationRepository extends Mock implements DestinationRepository {}

void main() {
  late MockDestinationRepository repo;
  const destinationId = 'dest-1';

  CommentModel comment(String id, String content, {DateTime? at}) {
    return CommentModel(
      id: id,
      destinationId: destinationId,
      authorDeviceId: 'device-1',
      authorDisplayName: 'Alice',
      content: content,
      createdAt: at ?? DateTime.utc(2026, 4, 25, 10),
    );
  }

  setUp(() {
    repo = MockDestinationRepository();
  });

  group('DestinationCommentBloc', () {
    blocTest<DestinationCommentBloc, DestinationCommentState>(
      'loadComments_success_emitsLoadedWithList',
      build: () {
        when(() => repo.listComments(destinationId)).thenAnswer(
          (_) async => [comment('1', 'first'), comment('2', 'second')],
        );
        return DestinationCommentBloc(repo);
      },
      act: (b) => b.add(const LoadComments(destinationId)),
      expect: () => [
        const DestinationCommentState.loading(),
        isA<DestinationCommentState>().having(
          (s) => s.maybeWhen(
            loaded: (comments, _, _) => comments.length,
            orElse: () => -1,
          ),
          'loaded count',
          2,
        ),
      ],
    );

    blocTest<DestinationCommentBloc, DestinationCommentState>(
      'loadComments_failure_emitsError',
      build: () {
        when(() => repo.listComments(destinationId)).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 403,
            ),
          ),
        );
        return DestinationCommentBloc(repo);
      },
      act: (b) => b.add(const LoadComments(destinationId)),
      expect: () => [
        const DestinationCommentState.loading(),
        isA<DestinationCommentState>().having(
          (s) => s.maybeWhen(
            error: (m) => m,
            orElse: () => '',
          ),
          'error message',
          contains('member'),
        ),
      ],
    );

    blocTest<DestinationCommentBloc, DestinationCommentState>(
      'addComment_optimisticallyAppendsThenReconciles',
      build: () {
        when(() => repo.addComment(
              destinationId: destinationId,
              content: any(named: 'content'),
            )).thenAnswer((_) async => comment('server-1', 'hello'));
        return DestinationCommentBloc(repo);
      },
      seed: () => DestinationCommentState.loaded(comments: [comment('0', 'prev')]),
      act: (b) => b.add(const AddComment(destinationId, 'hello')),
      expect: () => [
        isA<DestinationCommentState>().having(
          (s) => s.maybeWhen(
            loaded: (comments, submitting, _) =>
                submitting && comments.length == 2 && comments.last.pending,
            orElse: () => false,
          ),
          'optimistic pending',
          true,
        ),
        isA<DestinationCommentState>().having(
          (s) => s.maybeWhen(
            loaded: (comments, submitting, _) =>
                !submitting &&
                comments.length == 2 &&
                comments.last.id == 'server-1',
            orElse: () => false,
          ),
          'reconciled',
          true,
        ),
      ],
    );

    blocTest<DestinationCommentBloc, DestinationCommentState>(
      'addComment_failureRemovesTempAndSurfacesError',
      build: () {
        when(() => repo.addComment(
              destinationId: destinationId,
              content: any(named: 'content'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 500,
          ),
        ));
        return DestinationCommentBloc(repo);
      },
      seed: () => DestinationCommentState.loaded(comments: [comment('0', 'prev')]),
      act: (b) => b.add(const AddComment(destinationId, 'hi')),
      skip: 1,
      expect: () => [
        isA<DestinationCommentState>().having(
          (s) => s.maybeWhen(
            loaded: (comments, submitting, submitError) =>
                !submitting &&
                comments.length == 1 &&
                submitError != null,
            orElse: () => false,
          ),
          'rolled-back + error',
          true,
        ),
      ],
    );

    blocTest<DestinationCommentBloc, DestinationCommentState>(
      'addComment_blankContent_doesNotCallRepository',
      build: () => DestinationCommentBloc(repo),
      seed: () => const DestinationCommentState.loaded(comments: []),
      act: (b) => b.add(const AddComment(destinationId, '   ')),
      expect: () => [],
      verify: (_) {
        verifyNever(() => repo.addComment(
            destinationId: any(named: 'destinationId'),
            content: any(named: 'content')));
      },
    );

    blocTest<DestinationCommentBloc, DestinationCommentState>(
      'addComment_tooLong_doesNotCallRepository',
      build: () => DestinationCommentBloc(repo),
      seed: () => const DestinationCommentState.loaded(comments: []),
      act: (b) => b.add(AddComment(destinationId, 'a' * 2001)),
      expect: () => [],
    );

    blocTest<DestinationCommentBloc, DestinationCommentState>(
      'addComment_preservesOrderOnRapidSubmit',
      build: () {
        var counter = 0;
        when(() => repo.addComment(
              destinationId: destinationId,
              content: any(named: 'content'),
            )).thenAnswer((invocation) async {
          final content = invocation.namedArguments[#content] as String;
          counter++;
          await Future<void>.delayed(Duration(milliseconds: 10 * (4 - counter)));
          return comment('server-$counter', content);
        });
        return DestinationCommentBloc(repo);
      },
      seed: () => const DestinationCommentState.loaded(comments: []),
      act: (b) => b
        ..add(const AddComment(destinationId, 'one'))
        ..add(const AddComment(destinationId, 'two'))
        ..add(const AddComment(destinationId, 'three')),
      wait: const Duration(milliseconds: 200),
      verify: (_) {
        final captured = verify(() => repo.addComment(
              destinationId: destinationId,
              content: captureAny(named: 'content'),
            )).captured;
        expect(captured, ['one', 'two', 'three']);
      },
    );
  });
}
