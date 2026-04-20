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
  Object? _lastBannerIdentity;

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
        listener: _handleBanner,
        builder: (context, state) {
          return state.when(
            initial: _buildSpinner,
            loading: _buildSpinner,
            error: (message) => _buildError(context, message),
            loaded: (detail, myDeviceId, _, connectionBanner) =>
                _buildLoaded(context, detail, myDeviceId, connectionBanner),
          );
        },
      ),
    );
  }

  void _handleBanner(BuildContext context, PollDetailState state) {
    final banner = state.whenOrNull(
      loaded: (_, _, errorBanner, _) => errorBanner,
    );
    if (banner == null || banner.isEmpty) {
      _lastBannerIdentity = null;
      return;
    }
    // Key dedup on the state instance, not the message, so identical messages
    // emitted in distinct loaded() states each surface a SnackBar.
    final identity = state;
    if (identical(identity, _lastBannerIdentity)) return;
    _lastBannerIdentity = identity;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(banner),
        duration: const Duration(seconds: 3),
      ));
  }

  Widget _buildSpinner() =>
      const Center(child: CircularProgressIndicator());

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
      String? connectionBanner) {
    final theme = Theme.of(context);
    final isLocked = detail.status == PollStatus.locked;
    final chipColor = isLocked
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.primary;

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
            onVote: isLocked
                ? null
                : (slotId, status) => context
                    .read<PollDetailBloc>()
                    .add(CastVote(slotId: slotId, status: status)),
          ),
        ),
      ],
    );
  }
}
