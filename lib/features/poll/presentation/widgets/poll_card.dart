import 'package:flutter/material.dart';

import '../../domain/model/poll_model.dart';

class PollCard extends StatelessWidget {
  final PollModel poll;
  final VoidCallback? onTap;

  const PollCard({super.key, required this.poll, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOpen = poll.status == PollStatus.open;
    final chipColor = isOpen
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(poll.title),
        subtitle: Text(
          '${poll.slots.length} date${poll.slots.length == 1 ? '' : 's'}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Chip(
          label: Text(isOpen ? 'OPEN' : 'LOCKED'),
          backgroundColor: chipColor.withValues(alpha: 0.12),
          labelStyle: TextStyle(color: chipColor, fontWeight: FontWeight.w600),
          side: BorderSide.none,
        ),
        onTap: onTap ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vote feature coming soon')),
              );
            },
      ),
    );
  }
}
