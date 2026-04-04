import 'package:flutter/material.dart';

class TripProgressIndicator extends StatelessWidget {
  final bool datesConfirmed;
  final bool destinationChosen;
  final bool hasExpenses;
  final bool hasTasks;

  const TripProgressIndicator({
    super.key,
    required this.datesConfirmed,
    required this.destinationChosen,
    required this.hasExpenses,
    required this.hasTasks,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      _Step(label: 'Dates', completed: datesConfirmed),
      _Step(label: 'Destination', completed: destinationChosen),
      _Step(label: 'Expenses', completed: hasExpenses),
      _Step(label: 'Tasks', completed: hasTasks),
    ];

    return SizedBox(
      height: 48,
      child: Row(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            _StepCircle(step: steps[i]),
            if (i < steps.length - 1) Expanded(child: _StepLine(step: steps[i])),
          ],
        ],
      ),
    );
  }
}

class _Step {
  final String label;
  final bool completed;

  const _Step({required this.label, required this.completed});
}

class _StepCircle extends StatelessWidget {
  final _Step step;

  const _StepCircle({required this.step});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: step.label,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: step.completed ? colorScheme.primary : Colors.transparent,
          border: Border.all(
            color:
                step.completed ? colorScheme.primary : colorScheme.outlineVariant,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: step.completed
            ? Icon(Icons.check, size: 16, color: colorScheme.onPrimary)
            : null,
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  final _Step step;

  const _StepLine({required this.step});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 2,
      color: step.completed ? colorScheme.primary : colorScheme.outlineVariant,
    );
  }
}
