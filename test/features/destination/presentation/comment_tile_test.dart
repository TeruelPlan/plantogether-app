import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantogether_app/features/destination/domain/model/comment_model.dart';
import 'package:plantogether_app/features/destination/presentation/widgets/comment_tile.dart';

void main() {
  group('CommentTile', () {
    testWidgets('renders author display name and content', (tester) async {
      final c = CommentModel(
        id: 'c-1',
        destinationId: 'd-1',
        authorDeviceId: 'dev-1',
        authorDisplayName: 'Alice',
        content: 'Looks great!',
        createdAt: DateTime.utc(2026, 4, 25, 10, 30),
      );

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: CommentTile(comment: c))),
      );

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Looks great!'), findsOneWidget);
      expect(find.byKey(const ValueKey('comment_body_c-1')), findsOneWidget);
    });

    testWidgets('falls back to Unknown member when display name empty',
        (tester) async {
      final c = CommentModel(
        id: 'c-2',
        destinationId: 'd-1',
        authorDeviceId: 'dev-1',
        authorDisplayName: '',
        content: 'x',
        createdAt: DateTime.utc(2026, 4, 25, 10, 30),
      );

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: CommentTile(comment: c))),
      );

      expect(find.text('Unknown member'), findsOneWidget);
    });
  });
}
