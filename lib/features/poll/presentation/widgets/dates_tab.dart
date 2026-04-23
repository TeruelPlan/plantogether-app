import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/poll_bloc.dart';
import '../bloc/poll_event.dart';
import '../bloc/poll_state.dart';
import 'create_poll_sheet.dart';
import 'poll_card.dart';

class DatesTab extends StatefulWidget {
  final String tripId;

  const DatesTab({super.key, required this.tripId});

  @override
  State<DatesTab> createState() => _DatesTabState();
}

class _DatesTabState extends State<DatesTab> {
  @override
  void initState() {
    super.initState();
    context.read<PollBloc>().add(LoadPolls(widget.tripId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<PollBloc, PollState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (message) => _buildError(context, message),
            loaded: (polls) => polls.isEmpty
                ? _buildEmpty(context)
                : ListView.builder(
                    key: const ValueKey('polls_list'),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: polls.length,
                    itemBuilder: (_, i) => PollCard(
                      key: ValueKey('poll_card_${polls[i].id}'),
                      poll: polls[i],
                      onTap: () => context.push(
                          '/trips/${widget.tripId}/polls/${polls[i].id}'),
                    ),
                  ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('poll_create_fab'),
        onPressed: () => CreatePollSheet.show(context, widget.tripId),
        tooltip: 'Create poll',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Failed to load polls',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(message, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('polls_retry_button'),
            onPressed: () =>
                context.read<PollBloc>().add(LoadPolls(widget.tripId)),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      key: const ValueKey('polls_empty_state'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('No date poll yet',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Tap + to create one',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
