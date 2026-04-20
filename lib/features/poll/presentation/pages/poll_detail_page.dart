import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/offline_sync_banner.dart';
import '../../domain/model/poll_model.dart';
import '../bloc/poll_detail_bloc.dart';
import '../bloc/poll_detail_event.dart';
import '../bloc/poll_detail_state.dart';
import '../widgets/date_poll_matrix_widget.dart';

class PollDetailPage extends StatefulWidget {
  final String pollId;

  const PollDetailPage({super.key, required this.pollId});

  @override
  State<PollDetailPage> createState() => _PollDetailPageState();
}

class _PollDetailPageState extends State<PollDetailPage> {
  Object? _lastErrorBannerIdentity;
  Object? _lastSuccessBannerIdentity;

  @override
  void initState() {
    super.initState();
    context.read<PollDetailBloc>().add(LoadPollDetail(widget.pollId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Poll'),
      ),
      body: BlocConsumer<PollDetailBloc, PollDetailState>(
        listener: _handleBanners,
        builder: (context, state) {
          return state.when(
            initial: _buildSpinner,
            loading: _buildSpinner,
            error: (message) => _buildError(context, message),
            loaded: (detail, myDeviceId, _, connectionBanner, _, locking) =>
                _buildLoaded(
                    context, detail, myDeviceId, connectionBanner, locking),
          );
        },
      ),
    );
  }

  void _handleBanners(BuildContext context, PollDetailState state) {
    state.whenOrNull(
      loaded: (_, _, errorBanner, _, successBanner, _) {
        _surfaceErrorBanner(context, state, errorBanner);
        _surfaceSuccessBanner(context, state, successBanner);
      },
    );
  }

  void _surfaceErrorBanner(
      BuildContext context, PollDetailState state, String? banner) {
    if (banner == null || banner.isEmpty) {
      _lastErrorBannerIdentity = null;
      return;
    }
    if (identical(state, _lastErrorBannerIdentity)) return;
    _lastErrorBannerIdentity = state;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(banner),
        duration: const Duration(seconds: 3),
      ));
    context.read<PollDetailBloc>().add(const ErrorBannerConsumed());
  }

  void _surfaceSuccessBanner(
      BuildContext context, PollDetailState state, String? banner) {
    if (banner == null || banner.isEmpty) {
      _lastSuccessBannerIdentity = null;
      return;
    }
    if (identical(state, _lastSuccessBannerIdentity)) return;
    _lastSuccessBannerIdentity = state;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle,
                color: theme.colorScheme.onPrimaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                banner,
                style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.primaryContainer,
        duration: const Duration(seconds: 4),
      ));
    context.read<PollDetailBloc>().add(const SuccessBannerConsumed());
  }

  Widget _buildSpinner() => const Center(child: CircularProgressIndicator());

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Failed to load poll',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(message, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context
                .read<PollDetailBloc>()
                .add(LoadPollDetail(widget.pollId)),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoaded(
      BuildContext context,
      PollDetailModel detail,
      String myDeviceId,
      String? connectionBanner,
      bool locking) {
    final theme = Theme.of(context);
    final isLocked = detail.status == PollStatus.locked;
    final chipColor = isLocked
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.primary;
    final me = detail.members.firstWhere(
      (m) => m.deviceId == myDeviceId,
      orElse: () => const PollMemberModel(
          deviceId: '', role: 'PARTICIPANT', displayName: ''),
    );
    final isOrganizer = me.role == 'ORGANIZER';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (connectionBanner != null)
          OfflineSyncBanner(message: connectionBanner),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  detail.title,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              Chip(
                label: Text(isLocked ? 'LOCKED' : 'OPEN'),
                backgroundColor: chipColor.withValues(alpha: 0.12),
                labelStyle:
                    TextStyle(color: chipColor, fontWeight: FontWeight.w600),
                side: BorderSide.none,
              ),
            ],
          ),
        ),
        Expanded(
          child: DatePollMatrixWidget(
            detail: detail,
            myDeviceId: myDeviceId,
            isLocked: isLocked,
            isOrganizer: isOrganizer,
            locking: locking,
            onVote: isLocked
                ? null
                : (slotId, status) => context
                    .read<PollDetailBloc>()
                    .add(CastVote(slotId: slotId, status: status)),
            onLockTap: (isLocked || !isOrganizer)
                ? null
                : (slotId) => _confirmAndLock(context, detail, slotId),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAndLock(
      BuildContext context, PollDetailModel detail, String slotId) async {
    final slot = detail.slots.firstWhere(
      (s) => s.id == slotId,
      orElse: () => detail.slots.first,
    );
    final label = DatePollMatrixWidget.formatSlotLabel(slot);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Lock $label?'),
        content:
            const Text('All members will be notified. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lock'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    context.read<PollDetailBloc>().add(LockPoll(slotId));
  }
}
