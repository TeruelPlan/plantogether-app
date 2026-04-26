import 'package:flutter/material.dart';

import '../../domain/model/destination_model.dart';

class DestinationProposalCard extends StatelessWidget {
  final DestinationModel destination;
  final VoidCallback? onTap;
  final Widget? voteInput;
  final Widget? commentsSlot;
  final bool isLeading;
  final String? aggregateLabel;
  final Widget? organizerAction;

  const DestinationProposalCard({
    super.key,
    required this.destination,
    this.onTap,
    this.voteInput,
    this.commentsSlot,
    this.isLeading = false,
    this.aggregateLabel,
    this.organizerAction,
  });

  bool get _isChosen => destination.status == DestinationStatus.chosen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final budget = destination.estimatedBudget;
    final currency = destination.currency;
    final trailing = (budget != null && currency != null)
        ? Text(
            '${budget.toStringAsFixed(0)} $currency',
            style: theme.textTheme.titleSmall,
          )
        : null;

    final label = aggregateLabel ?? '';
    final semanticsLabel =
        'Destination ${destination.name}${label.isEmpty ? '' : ', $label'}'
        '${isLeading ? ', leading' : ''}';

    return Semantics(
      liveRegion: true,
      container: true,
      label: semanticsLabel,
      child: Card(
        key: _isChosen
            ? ValueKey('destination_card_chosen_${destination.id}')
            : (isLeading
                ? ValueKey('destination_card_leading_${destination.id}')
                : null),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: (_isChosen || isLeading)
            ? colorScheme.primaryContainer.withValues(alpha: 0.35)
            : null,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.image_outlined,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  destination.name,
                                  style: theme.textTheme.titleMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_isChosen) ...[
                                const SizedBox(width: 6),
                                Chip(
                                  key: ValueKey(
                                      'destination_chosen_badge_${destination.id}'),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  avatar: Icon(
                                    Icons.check_circle,
                                    size: 18,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                  label: const Text('Selected ✓'),
                                  backgroundColor:
                                      colorScheme.primaryContainer,
                                ),
                              ] else if (isLeading) ...[
                                const SizedBox(width: 6),
                                Chip(
                                  key: ValueKey(
                                      'destination_leading_badge_${destination.id}'),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  avatar: Icon(
                                    Icons.emoji_events,
                                    size: 18,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                  label: const Text('Leading'),
                                  backgroundColor: colorScheme.primaryContainer,
                                ),
                              ],
                            ],
                          ),
                          if (destination.description != null &&
                              destination.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              destination.description!,
                              style: theme.textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (destination.externalUrl != null &&
                              destination.externalUrl!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              destination.externalUrl!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (aggregateLabel != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              aggregateLabel!,
                              key: ValueKey(
                                  'destination_aggregate_label_${destination.id}'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing,
                    ],
                  ],
                ),
                if (voteInput != null) ...[
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 4),
                  voteInput!,
                ],
                if (commentsSlot != null) ...[
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 4),
                  commentsSlot!,
                ],
                if (organizerAction != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: organizerAction!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
