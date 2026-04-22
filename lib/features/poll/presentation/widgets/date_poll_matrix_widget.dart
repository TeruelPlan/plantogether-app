import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/member_avatar.dart';
import '../../domain/model/poll_model.dart';

class DatePollMatrixWidget extends StatelessWidget {
  final PollDetailModel detail;
  final String myDeviceId;
  final bool isLocked;
  final bool isOrganizer;
  final bool locking;
  final void Function(String slotId, VoteStatus status)? onVote;
  final ValueChanged<String>? onLockTap;

  const DatePollMatrixWidget({
    super.key,
    required this.detail,
    required this.myDeviceId,
    required this.isLocked,
    this.isOrganizer = false,
    this.locking = false,
    this.onVote,
    this.onLockTap,
  });

  static final DateFormat _monthDay = DateFormat('MMM d');

  @override
  Widget build(BuildContext context) {
    if (detail.slots.isEmpty) {
      return const Center(child: Text('No slots'));
    }

    final theme = Theme.of(context);
    final members = detail.members;
    final hasVotes = detail.slots.any((s) => s.score > 0);
    final maxScore =
        detail.slots.fold<int>(0, (acc, s) => math.max(acc, s.score));

    final compact = MediaQuery.of(context).size.width < 600 && members.length > 4;

    final lockedSlotId = isLocked ? detail.lockedSlotId : null;

    PollSlotDetailModel? lockedSlot;
    if (lockedSlotId != null) {
      for (final s in detail.slots) {
        if (s.id == lockedSlotId) {
          lockedSlot = s;
          break;
        }
      }
    }

    final matrix = _MatrixContent(
      slots: detail.slots,
      members: members,
      myDeviceId: myDeviceId,
      isLocked: isLocked,
      isOrganizer: isOrganizer,
      locking: locking,
      onVote: onVote,
      onLockTap: onLockTap,
      maxScore: maxScore,
      lockedSlotId: lockedSlotId,
      compact: compact,
    );

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isLocked && lockedSlot != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Semantics(
                  label:
                      'Poll confirmed: ${_monthDay.format(lockedSlot.startDate)} to ${_monthDay.format(lockedSlot.endDate)}',
                  child: Chip(
                    avatar: Icon(Icons.check_circle,
                        color: theme.colorScheme.onPrimaryContainer),
                    label: const Text('Confirmed ✓'),
                    backgroundColor: theme.colorScheme.primaryContainer,
                  ),
                ),
              ),
            ),
          if (!hasVotes && !isLocked)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Be the first to vote · Tap a slot to respond',
                style: theme.textTheme.bodySmall,
              ),
            ),
          Expanded(child: matrix),
        ],
      ),
    );
  }

  static String formatSlotLabel(PollSlotDetailModel slot) {
    return '${_monthDay.format(slot.startDate)}–${_monthDay.format(slot.endDate)}';
  }

  static String semanticSlotLabel(PollSlotDetailModel slot) {
    return '${_monthDay.format(slot.startDate)} to ${_monthDay.format(slot.endDate)}';
  }
}

class _MatrixContent extends StatefulWidget {
  final List<PollSlotDetailModel> slots;
  final List<PollMemberModel> members;
  final String myDeviceId;
  final bool isLocked;
  final bool isOrganizer;
  final bool locking;
  final void Function(String slotId, VoteStatus status)? onVote;
  final ValueChanged<String>? onLockTap;
  final int maxScore;
  final String? lockedSlotId;
  final bool compact;

  const _MatrixContent({
    required this.slots,
    required this.members,
    required this.myDeviceId,
    required this.isLocked,
    required this.isOrganizer,
    required this.locking,
    required this.onVote,
    required this.onLockTap,
    required this.maxScore,
    required this.lockedSlotId,
    required this.compact,
  });

  @override
  State<_MatrixContent> createState() => _MatrixContentState();
}

class _MatrixContentState extends State<_MatrixContent> {
  ScrollController? _scrollController;

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Intrinsic width keeps header and slot rows aligned; shared horizontal scroll
    // kicks in on narrow screens when there are enough members to overflow.
    final innerWidth = 110 + (widget.members.length * 48) + 56;
    final header = _HeaderRow(members: widget.members);
    final rows = ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.slots.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final slot = widget.slots[index];
        final bool isWinner;
        if (widget.isLocked) {
          isWinner = slot.id == widget.lockedSlotId;
        } else {
          isWinner = widget.maxScore > 0 && slot.score == widget.maxScore;
        }
        final canLock = !widget.isLocked && widget.isOrganizer;
        return _SlotRow(
          slot: slot,
          members: widget.members,
          myDeviceId: widget.myDeviceId,
          isLocked: widget.isLocked,
          isWinner: isWinner,
          label: DatePollMatrixWidget.formatSlotLabel(slot),
          onVote: widget.onVote,
          canLock: canLock,
          locking: widget.locking,
          onLockTap: widget.onLockTap,
        );
      },
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const Divider(height: 1),
        Expanded(child: rows),
      ],
    );

    if (!widget.compact) {
      _scrollController?.dispose();
      _scrollController = null;
      return body;
    }

    final controller = _scrollController ??= ScrollController();
    return Scrollbar(
      controller: controller,
      child: SingleChildScrollView(
        controller: controller,
        scrollDirection: Axis.horizontal,
        child: SizedBox(width: innerWidth.toDouble(), child: body),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final List<PollMemberModel> members;

  const _HeaderRow({required this.members});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 110),
          ...members.map((m) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    MemberAvatar(
                        deviceId: m.deviceId,
                        displayName: m.displayName,
                        size: 32),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 56,
                      child: Text(
                        _truncate(m.displayName),
                        style: textTheme.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  static String _truncate(String name) {
    if (name.length <= 10) return name;
    return '${name.substring(0, 9)}…';
  }
}

class _SlotRow extends StatelessWidget {
  final PollSlotDetailModel slot;
  final List<PollMemberModel> members;
  final String myDeviceId;
  final bool isLocked;
  final bool isWinner;
  final String label;
  final void Function(String slotId, VoteStatus status)? onVote;
  final bool canLock;
  final bool locking;
  final ValueChanged<String>? onLockTap;

  const _SlotRow({
    required this.slot,
    required this.members,
    required this.myDeviceId,
    required this.isLocked,
    required this.isWinner,
    required this.label,
    required this.onVote,
    required this.canLock,
    required this.locking,
    required this.onLockTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decoration = isWinner
        ? BoxDecoration(color: theme.colorScheme.primaryContainer)
        : null;

    final votesByDevice = <String, VoteStatus>{
      for (final v in slot.votes) v.deviceId: v.status,
    };

    return Container(
      decoration: decoration,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.titleSmall,
            ),
          ),
          ...members.map((m) {
            final vote = votesByDevice[m.deviceId];
            final isMe = m.deviceId == myDeviceId;
            return Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: (isMe && !isLocked)
                    ? _OwnVoteCell(
                        slot: slot,
                        member: m,
                        currentVote: vote,
                        isLocked: isLocked,
                        slotLabel: label,
                        onVote: onVote,
                      )
                    : _ReadOnlyVoteCell(
                        vote: vote,
                        memberName: m.displayName,
                        slotLabel: label,
                      ),
              ),
            );
          }),
          const SizedBox(width: 8),
          Semantics(
            container: true,
            liveRegion: true,
            label: 'Score ${slot.score}',
            child: Text(
              '${slot.score}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (canLock)
            Semantics(
              label:
                  'Lock poll for ${DatePollMatrixWidget.semanticSlotLabel(slot)}',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.lock_outline, size: 18),
                tooltip: 'Lock dates',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 32, maxWidth: 40, minHeight: 32, maxHeight: 40),
                onPressed: locking ? null : () => onLockTap?.call(slot.id),
              ),
            ),
        ],
      ),
    );
  }

}

class _OwnVoteCell extends StatelessWidget {
  final PollSlotDetailModel slot;
  final PollMemberModel member;
  final VoteStatus? currentVote;
  final bool isLocked;
  final String slotLabel;
  final void Function(String slotId, VoteStatus status)? onVote;

  const _OwnVoteCell({
    required this.slot,
    required this.member,
    required this.currentVote,
    required this.isLocked,
    required this.slotLabel,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label:
          'Your vote: ${currentVote?.name.toUpperCase() ?? 'none'} for $slotLabel',
      child: SegmentedButton<VoteStatus>(
        segments: const [
          ButtonSegment(value: VoteStatus.yes, icon: Icon(Icons.check)),
          ButtonSegment(value: VoteStatus.maybe, icon: Icon(Icons.help_outline)),
          ButtonSegment(value: VoteStatus.no, icon: Icon(Icons.close)),
        ],
        showSelectedIcon: false,
        selected: currentVote != null ? {currentVote!} : <VoteStatus>{},
        emptySelectionAllowed: currentVote == null,
        multiSelectionEnabled: false,
        onSelectionChanged: isLocked
            ? null
            : (selection) {
                if (selection.isEmpty) return;
                onVote?.call(slot.id, selection.first);
              },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (!states.contains(WidgetState.selected)) return null;
            switch (currentVote) {
              case VoteStatus.yes:
                return theme.colorScheme.tertiaryContainer;
              case VoteStatus.maybe:
                return theme.colorScheme.secondaryContainer;
              case VoteStatus.no:
                return theme.colorScheme.errorContainer;
              case null:
                return null;
            }
          }),
        ),
      ),
    );
  }
}

class _ReadOnlyVoteCell extends StatelessWidget {
  final VoteStatus? vote;
  final String memberName;
  final String slotLabel;

  const _ReadOnlyVoteCell({
    required this.vote,
    required this.memberName,
    required this.slotLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Color? bg;
    IconData? icon;
    Color? iconColor;
    switch (vote) {
      case VoteStatus.yes:
        bg = colorScheme.tertiaryContainer;
        icon = Icons.check;
        iconColor = colorScheme.onTertiaryContainer;
        break;
      case VoteStatus.maybe:
        bg = colorScheme.secondaryContainer;
        icon = Icons.help_outline;
        iconColor = colorScheme.onSecondaryContainer;
        break;
      case VoteStatus.no:
        bg = colorScheme.errorContainer;
        icon = Icons.close;
        iconColor = colorScheme.onErrorContainer;
        break;
      case null:
        bg = null;
        icon = null;
        iconColor = null;
        break;
    }

    final inner = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: icon == null ? null : Icon(icon, color: iconColor, size: 20),
    );
    final cell = vote == null
        ? CustomPaint(
            painter: _DashedBorderPainter(
              color: colorScheme.outline,
              strokeWidth: 1,
              radius: 8,
              dashWidth: 4,
              dashGap: 3,
            ),
            child: inner,
          )
        : inner;

    return Semantics(
      label:
          'Vote ${vote?.name.toUpperCase() ?? 'none'} for $slotLabel, $memberName',
      child: cell,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashWidth;
  final double dashGap;

  const _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dashWidth,
    required this.dashGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);
    final metrics = path.computeMetrics().toList();
    final dashed = Path();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final next = math.min(distance + dashWidth, metric.length);
        dashed.addPath(metric.extractPath(distance, next), Offset.zero);
        distance = next + dashGap;
      }
    }
    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.radius != radius ||
      old.dashWidth != dashWidth ||
      old.dashGap != dashGap;
}
