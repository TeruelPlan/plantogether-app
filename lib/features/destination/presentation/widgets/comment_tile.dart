import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/model/comment_model.dart';

class CommentTile extends StatelessWidget {
  final CommentModel comment;

  const CommentTile({super.key, required this.comment});

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final isSameDay =
        local.year == now.year && local.month == now.month && local.day == now.day;
    if (isSameDay) {
      return DateFormat.Hm().format(local);
    }
    return DateFormat.MMMd().add_Hm().format(local);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = comment.authorDisplayName.isEmpty
        ? 'Unknown member'
        : comment.authorDisplayName;
    return Opacity(
      opacity: comment.pending ? 0.6 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              key: ValueKey('comment_avatar_${comment.id}'),
              radius: 16,
              child: Text(
                displayName.isNotEmpty
                    ? displayName.characters.first.toUpperCase()
                    : '?',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        displayName,
                        key: ValueKey('comment_author_${comment.id}'),
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(comment.createdAt),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    comment.content,
                    key: ValueKey('comment_body_${comment.id}'),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
