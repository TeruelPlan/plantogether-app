import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/destination/domain/model/comment_model.dart';
import 'package:plantogether_app/features/destination/domain/repository/destination_repository.dart';
import 'package:plantogether_app/features/destination/presentation/bloc/destination_comment_bloc.dart';
import 'package:plantogether_app/features/destination/presentation/widgets/comment_thread_widget.dart';

class MockDestinationRepository extends Mock implements DestinationRepository {}

Widget _wrap(Widget child, DestinationCommentBloc bloc) {
  return MaterialApp(
    home: Scaffold(
      body: BlocProvider.value(value: bloc, child: child),
    ),
  );
}

void main() {
  late MockDestinationRepository repo;

  setUp(() {
    repo = MockDestinationRepository();
  });

  testWidgets('shows empty state copy when no comments', (tester) async {
    when(() => repo.listComments('d-1')).thenAnswer((_) async => []);
    final bloc = DestinationCommentBloc(repo);

    await tester
        .pumpWidget(_wrap(const CommentThreadWidget(destinationId: 'd-1'), bloc));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('comment_thread_empty_state')),
        findsOneWidget);
    expect(find.text('No comments yet · Be the first to share your thoughts'),
        findsOneWidget);
  });

  testWidgets('send button dispatches AddComment with trimmed text',
      (tester) async {
    when(() => repo.listComments('d-1')).thenAnswer((_) async => []);
    when(() => repo.addComment(
          destinationId: 'd-1',
          content: any(named: 'content'),
        )).thenAnswer((_) async => CommentModel(
          id: 'srv-1',
          destinationId: 'd-1',
          authorDeviceId: 'dev',
          authorDisplayName: 'Alice',
          content: 'hi',
          createdAt: DateTime.utc(2026, 4, 25),
        ));
    final bloc = DestinationCommentBloc(repo);

    await tester
        .pumpWidget(_wrap(const CommentThreadWidget(destinationId: 'd-1'), bloc));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('comment_input_field')), '  hi  ');
    await tester.tap(find.byKey(const ValueKey('comment_send_button')));
    await tester.pumpAndSettle();

    verify(() => repo.addComment(destinationId: 'd-1', content: 'hi')).called(1);
  });

  testWidgets('blank input shows inline helper and does not dispatch',
      (tester) async {
    when(() => repo.listComments('d-1')).thenAnswer((_) async => []);
    final bloc = DestinationCommentBloc(repo);

    await tester
        .pumpWidget(_wrap(const CommentThreadWidget(destinationId: 'd-1'), bloc));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('comment_send_button')));
    await tester.pumpAndSettle();

    expect(find.text('Comment cannot be empty'), findsOneWidget);
    verifyNever(() => repo.addComment(
        destinationId: any(named: 'destinationId'),
        content: any(named: 'content')));
  });

  testWidgets('send button is disabled while submitting', (tester) async {
    when(() => repo.listComments('d-1')).thenAnswer((_) async => []);
    when(() => repo.addComment(
          destinationId: 'd-1',
          content: any(named: 'content'),
        )).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return CommentModel(
        id: 'srv-1',
        destinationId: 'd-1',
        authorDeviceId: 'dev',
        authorDisplayName: 'Alice',
        content: 'hi',
        createdAt: DateTime.utc(2026, 4, 25),
      );
    });
    final bloc = DestinationCommentBloc(repo);

    await tester
        .pumpWidget(_wrap(const CommentThreadWidget(destinationId: 'd-1'), bloc));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('comment_input_field')), 'hi');
    await tester.tap(find.byKey(const ValueKey('comment_send_button')));
    await tester.pump(const Duration(milliseconds: 50));

    final IconButton sendButton = tester.widget<IconButton>(
      find.byKey(const ValueKey('comment_send_button')),
    );
    expect(sendButton.onPressed, isNull);

    final TextField input = tester.widget<TextField>(
      find.byKey(const ValueKey('comment_input_field')),
    );
    expect(input.enabled, isFalse);

    await tester.pumpAndSettle();
  });

  testWidgets('renders loaded comments', (tester) async {
    when(() => repo.listComments('d-1')).thenAnswer((_) async => [
          CommentModel(
            id: 'c-1',
            destinationId: 'd-1',
            authorDeviceId: 'dev',
            authorDisplayName: 'Alice',
            content: 'great',
            createdAt: DateTime.utc(2026, 4, 25, 10),
          ),
        ]);
    final bloc = DestinationCommentBloc(repo);

    await tester
        .pumpWidget(_wrap(const CommentThreadWidget(destinationId: 'd-1'), bloc));
    await tester.pumpAndSettle();

    expect(find.text('great'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
  });
}
