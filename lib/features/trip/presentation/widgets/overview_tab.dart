import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/models/member_info.dart';
import '../../../../shared/widgets/member_avatar_stack.dart';
import '../../domain/model/trip_model.dart';
import 'trip_progress_indicator.dart';
import 'trip_summary_card.dart';

class OverviewTab extends StatelessWidget {
  final TripModel trip;
  final bool isArchived;

  const OverviewTab({super.key, required this.trip, this.isArchived = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Archived banner
          if (isArchived)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.archive, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    'This trip is archived',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

          // Progress indicator
          TripProgressIndicator(
            datesConfirmed: trip.startDate != null && trip.endDate != null,
            destinationChosen: false,
            hasExpenses: false,
            hasTasks: false,
          ),
          const SizedBox(height: 24),

          // Member avatar row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${trip.memberCount} member${trip.memberCount == 1 ? '' : 's'}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(width: 8),
              if (trip.members.isNotEmpty)
                MemberAvatarStack(
                  members: trip.members.map((m) => MemberInfo(deviceId: m.deviceId, displayName: m.displayName)).toList(),
                  size: MemberAvatarSize.md,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Summary cards grid (2x2)
          _buildSummaryGrid(context),
          const SizedBox(height: 16),

          // Invite prompt when alone (hide for archived trips)
          if (trip.memberCount <= 1 && !isArchived)
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Invite members'),
                subtitle:
                    const Text('Share this trip with friends to plan together'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Navigate to invite page
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.4,
      children: [
        TripSummaryCard(
          icon: Icons.calendar_today,
          title: 'Dates',
          value: _formatDateRange(),
          emptyMessage: 'Create a date poll',
          onTap: () => _switchTab(context, 1),
        ),
        TripSummaryCard(
          icon: Icons.place,
          title: 'Destination',
          value: null,
          emptyMessage: 'Propose a destination',
          onTap: () => _switchTab(context, 2),
        ),
        TripSummaryCard(
          icon: Icons.account_balance_wallet,
          title: 'Expenses',
          value: null,
          emptyMessage: 'Add the first expense',
          onTap: () => _switchTab(context, 3),
        ),
        TripSummaryCard(
          icon: Icons.check_circle_outline,
          title: 'Tasks',
          value: null,
          emptyMessage: 'Add a task',
          onTap: () => _switchTab(context, 4),
        ),
      ],
    );
  }

  String? _formatDateRange() {
    if (trip.startDate == null || trip.endDate == null) return null;
    try {
      final start = DateTime.parse(trip.startDate!);
      final end = DateTime.parse(trip.endDate!);
      final fmt = DateFormat('MMM d');
      return '${fmt.format(start)} — ${fmt.format(end)}';
    } catch (_) {
      return '${trip.startDate} — ${trip.endDate}';
    }
  }

  void _switchTab(BuildContext context, int index) {
    DefaultTabController.of(context).animateTo(index);
  }
}
