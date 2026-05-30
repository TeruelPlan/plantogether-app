import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/member_avatar.dart';
import '../../../trip/domain/model/trip_model.dart';
import '../../domain/entity/balance.dart';
import '../bloc/balance/balance_bloc.dart';
import '../bloc/balance/balance_event.dart';
import '../bloc/balance/balance_state.dart';

enum SettlementVariant { summaryChip, fullScreen }

/// Renders the minimal settlement transfer list (story 5.4.1) with a per-row
/// "Mark done" action (story 5.4.2). Display names and avatars are resolved
/// from the trip member list already loaded in [trip] — never from the backend.
class SettlementArrowsWidget extends StatelessWidget {
  final TripModel trip;
  final String tripId;
  final String? myMemberId;
  final SettlementVariant variant;

  const SettlementArrowsWidget({
    super.key,
    required this.trip,
    required this.tripId,
    required this.myMemberId,
    this.variant = SettlementVariant.fullScreen,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BalanceBloc, BalanceState>(
      builder: (context, state) {
        return state.when(
          initial: () => const SizedBox.shrink(),
          loading: () => _loading(context),
          error: (message) => _error(context, message),
          loaded: (balance) => _loaded(context, balance),
        );
      },
    );
  }

  Widget _loading(BuildContext context) {
    if (variant == SettlementVariant.summaryChip) {
      return const SizedBox.shrink();
    }
    return const Center(
      key: ValueKey('settlement_loading'),
      child: CircularProgressIndicator(),
    );
  }

  Widget _error(BuildContext context, String message) {
    if (variant == SettlementVariant.summaryChip) {
      return const SizedBox.shrink();
    }
    return Center(
      key: const ValueKey('settlement_error'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 12),
          ElevatedButton(
            key: const ValueKey('settlement_retry_button'),
            onPressed: () =>
                context.read<BalanceBloc>().add(LoadBalance(tripId)),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _loaded(BuildContext context, Balance balance) {
    if (balance.settlements.isEmpty) {
      if (variant == SettlementVariant.summaryChip) {
        return const SizedBox.shrink();
      }
      return Center(
        key: const ValueKey('settlement_balanced_placeholder'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle_outline, size: 48),
            SizedBox(height: 8),
            Text('Trip is balanced'),
          ],
        ),
      );
    }

    if (variant == SettlementVariant.summaryChip) {
      return _summaryChip(context, balance);
    }

    if (balance.allSettled) {
      return _allSettled(context, balance);
    }

    return ListView.builder(
      key: const ValueKey('settlement_list'),
      shrinkWrap: true,
      itemCount: balance.settlements.length,
      itemBuilder: (context, index) =>
          _transferRow(context, balance, balance.settlements[index]),
    );
  }

  Widget _summaryChip(BuildContext context, Balance balance) {
    final count = balance.settlements.length;
    return Chip(
      key: const ValueKey('settlement_summary_chip'),
      avatar: const Icon(Icons.swap_horiz, size: 18),
      label: Text('$count transfer${count == 1 ? '' : 's'} to settle'),
    );
  }

  Widget _allSettled(BuildContext context, Balance balance) {
    return Center(
      key: const ValueKey('settlement_all_done'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.celebration_outlined, size: 48),
          SizedBox(height: 8),
          Text('Trip settled ✓'),
        ],
      ),
    );
  }

  Widget _transferRow(
    BuildContext context,
    Balance balance,
    SettlementTransfer transfer,
  ) {
    final theme = Theme.of(context);
    final fromName = _displayName(transfer.fromMemberId);
    final toName = _displayName(transfer.toMemberId);
    final amountLabel = _formatAmount(transfer.amount, transfer.currency);
    final isMine = myMemberId != null &&
        (transfer.fromMemberId == myMemberId ||
            transfer.toMemberId == myMemberId);
    final isDone = transfer.status == SettlementStatus.done;

    final rowKey =
        'settlement-row-${transfer.fromMemberId}-${transfer.toMemberId}-${transfer.amount}';

    return Semantics(
      label: '$fromName owes $toName $amountLabel'
          '${isDone ? ' · settled' : ''}.',
      child: Container(
        key: ValueKey(rowKey),
        color: isMine ? theme.colorScheme.primaryContainer : theme.colorScheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            MemberAvatar(seed: transfer.fromMemberId, displayName: fromName),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.arrow_forward,
                color: theme.colorScheme.secondary,
              ),
            ),
            MemberAvatar(seed: transfer.toMemberId, displayName: toName),
            const SizedBox(width: 12),
            Expanded(
              child: Text(amountLabel, style: theme.textTheme.titleMedium),
            ),
            if (isDone)
              Icon(Icons.check_circle, color: theme.colorScheme.primary)
            else
              IconButton(
                key: ValueKey(
                    'settlement-mark-done-${transfer.fromMemberId}-${transfer.toMemberId}-${transfer.amount}'),
                icon: const Icon(Icons.check_circle_outline),
                tooltip: 'Mark done',
                onPressed: () => context.read<BalanceBloc>().add(
                      MarkTransferDone(tripId: tripId, transfer: transfer),
                    ),
              ),
          ],
        ),
      ),
    );
  }

  String _displayName(String memberId) {
    for (final m in trip.members) {
      if (m.memberId == memberId) return m.displayName;
    }
    return 'Unknown';
  }

  String _formatAmount(double amount, String currency) {
    final format = NumberFormat.currency(name: currency, symbol: currency);
    return format.format(amount);
  }
}
