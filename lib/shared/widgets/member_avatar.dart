import 'package:flutter/material.dart';

import 'member_avatar_stack.dart';

/// Single circular avatar for a member. Deterministic colour from [seed]
/// (any stable per-member identifier — prefer trip_member_id), initial from
/// displayName. Reuses the palette from [MemberAvatarStack].
class MemberAvatar extends StatelessWidget {
  final String seed;
  final String displayName;
  final double size;

  const MemberAvatar({
    super.key,
    required this.seed,
    required this.displayName,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    final color = MemberAvatarStack.avatarColor(seed);
    final initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
