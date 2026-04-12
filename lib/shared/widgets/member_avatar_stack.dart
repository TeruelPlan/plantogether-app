import 'package:flutter/material.dart';

import '../models/member_info.dart';

enum MemberAvatarSize {
  sm(18),
  md(32),
  lg(40);

  final double diameter;
  const MemberAvatarSize(this.diameter);
}

class MemberAvatarStack extends StatelessWidget {
  final List<MemberInfo> members;
  final int maxVisible;
  final MemberAvatarSize size;
  final VoidCallback? onTap;

  const MemberAvatarStack({
    super.key,
    required this.members,
    this.maxVisible = 4,
    this.size = MemberAvatarSize.md,
    this.onTap,
  });

  static Color avatarColor(String memberId) {
    const colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
    ];
    return colors[(memberId.hashCode % colors.length + colors.length) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = members.take(maxVisible).toList();
    final overflow = members.length - maxVisible;
    final d = size.diameter;
    const overlap = 8.0;
    final totalWidth =
        visible.length * (d - overlap) + overlap + (overflow > 0 ? d : 0);

    final names = members.map((m) => m.displayName).toList();
    final String semanticsLabel;
    if (names.length <= maxVisible) {
      semanticsLabel = '${names.length} members: ${names.join(', ')}';
    } else {
      final visibleNames = names.take(maxVisible).join(', ');
      semanticsLabel =
          '${names.length} members: $visibleNames, and $overflow others';
    }

    return Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: totalWidth,
          height: d,
          child: Stack(
            children: [
              for (int i = 0; i < visible.length; i++)
                Positioned(
                  left: i * (d - overlap),
                  child: _Avatar(
                    member: visible[i],
                    diameter: d,
                  ),
                ),
              if (overflow > 0)
                Positioned(
                  left: visible.length * (d - overlap),
                  child: Container(
                    width: d,
                    height: d,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primaryContainer,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '+$overflow',
                      style: TextStyle(
                        fontSize: d * 0.35,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final MemberInfo member;
  final double diameter;

  const _Avatar({required this.member, required this.diameter});

  @override
  Widget build(BuildContext context) {
    final color = MemberAvatarStack.avatarColor(member.memberId);
    final initial =
        member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : '?';

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: diameter * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
