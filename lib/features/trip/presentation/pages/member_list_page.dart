import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/member_avatar_stack.dart';
import '../../domain/model/trip_member_model.dart';
import '../bloc/member_list_bloc.dart';
import '../bloc/member_list_event.dart';
import '../bloc/member_list_state.dart';
import '../widgets/remove_member_dialog.dart';

class MemberListPage extends StatefulWidget {
  final String tripId;

  const MemberListPage({
    super.key,
    required this.tripId,
  });

  @override
  State<MemberListPage> createState() => _MemberListPageState();
}

class _MemberListPageState extends State<MemberListPage> {
  @override
  void initState() {
    super.initState();
    context.read<MemberListBloc>().add(LoadMembers(widget.tripId));
  }

  bool _isOrganizer(List<TripMemberModel> members) {
    return members.any((m) => m.isMe && m.role == 'ORGANIZER');
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MemberListBloc, MemberListState>(
      listener: (context, state) {
        state.whenOrNull(
          failure: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          },
        );
      },
      builder: (context, state) {
        return state.when(
          initial: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          failure: (message) => Scaffold(
            appBar: AppBar(title: const Text('Members')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Failed to load members',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => context
                        .read<MemberListBloc>()
                        .add(LoadMembers(widget.tripId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          loaded: (members) {
            final isOrganizer = _isOrganizer(members);
            return Scaffold(
              appBar: AppBar(
                title: Text('Members (${members.length})'),
              ),
              body: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  final isMemberOrganizer = member.role == 'ORGANIZER';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          MemberAvatarStack.avatarColor(member.memberId),
                      child: Text(
                        member.displayName.trim().isNotEmpty
                            ? member.displayName.trim()[0].toUpperCase()
                            : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(member.displayName),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(isMemberOrganizer ? 'Organizer' : 'Member'),
                          backgroundColor: isMemberOrganizer
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerLow,
                          side: BorderSide.none,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    trailing: (isOrganizer && !member.isMe && !isMemberOrganizer)
                        ? IconButton(
                            icon: const Icon(Icons.person_remove_outlined),
                            tooltip: 'Remove member',
                            onPressed: () => RemoveMemberDialog.show(
                              context,
                              tripId: widget.tripId,
                              memberId: member.memberId,
                              displayName: member.displayName,
                            ),
                          )
                        : null,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
