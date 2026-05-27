import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/security/device_id_service.dart';
import '../../../trip/domain/repository/trip_repository.dart';
import '../../domain/repository/task_repository.dart';
import '../bloc/my_tasks_bloc.dart';
import '../bloc/my_tasks_event.dart';
import '../bloc/my_tasks_state.dart';

class MyTasksPage extends StatelessWidget {
  const MyTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => MyTasksBloc(
        ctx.read<TripRepository>(),
        ctx.read<TaskRepository>(),
        ctx.read<DeviceIdService>(),
      )..add(const LoadMyTasks()),
      child: const MyTasksView(),
    );
  }
}

/// Exported view widget so widget tests can inject a mock bloc
/// via BlocProvider.value without needing real repositories.
class MyTasksView extends StatelessWidget {
  const MyTasksView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
      ),
      body: BlocBuilder<MyTasksBloc, MyTasksState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (message) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    key: const ValueKey('my_tasks_retry_button'),
                    onPressed: () =>
                        context.read<MyTasksBloc>().add(const LoadMyTasks()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            loaded: (items, failedTripNames) =>
                _LoadedView(items: items, failedTripNames: failedTripNames),
          );
        },
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  final List<MyTaskItem> items;
  final List<String> failedTripNames;

  const _LoadedView({
    required this.items,
    required this.failedTripNames,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && failedTripNames.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "You're all caught up",
              key: ValueKey('my_tasks_empty_state'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    // Group items by tripId, preserving consistent order across concurrent loads.
    final tripOrder = <String>[];
    final grouped = <String, List<MyTaskItem>>{};
    for (final item in items) {
      if (!grouped.containsKey(item.tripId)) {
        tripOrder.add(item.tripId);
        grouped[item.tripId] = [];
      }
      grouped[item.tripId]!.add(item);
    }

    return Column(
      children: [
        if (failedTripNames.isNotEmpty)
          _FailedBanner(tripNames: failedTripNames),
        Expanded(
          child: ListView(
            key: const ValueKey('my_tasks_list'),
            children: [
              for (final tripId in tripOrder) ...[
                _TripSectionHeader(
                  tripName: grouped[tripId]!.first.tripName,
                ),
                for (final item in grouped[tripId]!)
                  _MyTaskTile(
                    key: ValueKey('my_task_item_${item.task.id}'),
                    item: item,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TripSectionHeader extends StatelessWidget {
  final String tripName;

  const _TripSectionHeader({required this.tripName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        tripName,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _MyTaskTile extends StatelessWidget {
  final MyTaskItem item;

  const _MyTaskTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(item.task.title),
      subtitle: Text(item.task.status.toWire().replaceAll('_', ' ')),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/trips/${item.tripId}'),
    );
  }
}

class _FailedBanner extends StatelessWidget {
  final List<String> tripNames;

  const _FailedBanner({required this.tripNames});

  @override
  Widget build(BuildContext context) {
    final joined = tripNames.join(', ');
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Could not load tasks for: $joined',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
