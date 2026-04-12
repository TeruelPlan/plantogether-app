import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantogether_app/shared/models/member_info.dart';
import 'package:plantogether_app/shared/widgets/member_avatar_stack.dart';

void main() {
  final sixMembers = List.generate(
    6,
    (i) => MemberInfo(
      memberId: 'member-$i',
      displayName: 'Member $i',
    ),
  );

  Widget buildTestWidget({
    required List<MemberInfo> members,
    int maxVisible = 4,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: MemberAvatarStack(
          members: members,
          maxVisible: maxVisible,
        ),
      ),
    );
  }

  group('MemberAvatarStack', () {
    testWidgets('shows max 4 avatars and overflow badge when 6 members',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(members: sixMembers));

      // Should show +2 overflow badge
      expect(find.text('+2'), findsOneWidget);

      // Should show first letters of the first 4 members
      expect(find.text('M'), findsNWidgets(4));
    });

    testWidgets('has correct accessibility label', (tester) async {
      await tester.pumpWidget(buildTestWidget(members: sixMembers));

      expect(
        find.bySemanticsLabel(
          '6 members: Member 0, Member 1, Member 2, Member 3, and 2 others',
        ),
        findsOneWidget,
      );
    });
  });
}
