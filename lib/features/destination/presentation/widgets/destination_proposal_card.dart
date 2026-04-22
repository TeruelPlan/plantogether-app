import 'package:flutter/material.dart';

import '../../domain/model/destination_model.dart';

class DestinationProposalCard extends StatelessWidget {
  final DestinationModel destination;
  final VoidCallback? onTap;

  const DestinationProposalCard({
    super.key,
    required this.destination,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final budget = destination.estimatedBudget;
    final currency = destination.currency;
    final trailing = (budget != null && currency != null)
        ? Text(
            '${budget.toStringAsFixed(0)} $currency',
            style: theme.textTheme.titleSmall,
          )
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.image_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                          color: theme.colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
        ),
      ),
    );
  }
}
