import 'package:flutter/material.dart';

/// Modal confirmation for an irreversible delete (story 5.3 AC 6).
/// Returns true when the user confirms, false / null when cancelled.
class ConfirmDeleteDialog extends StatefulWidget {
  final String title;
  final String body;

  const ConfirmDeleteDialog({
    super.key,
    this.title = 'Delete expense?',
    this.body = "This action can't be undone.",
  });

  static Future<bool?> show(
    BuildContext context, {
    String title = 'Delete expense?',
    String body = "This action can't be undone.",
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDeleteDialog(title: title, body: body),
    );
  }

  @override
  State<ConfirmDeleteDialog> createState() => _ConfirmDeleteDialogState();
}

class _ConfirmDeleteDialogState extends State<ConfirmDeleteDialog> {
  bool _submitted = false;

  void _confirm() {
    if (_submitted) return;
    setState(() => _submitted = true);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      key: const ValueKey('expense_confirm_delete_dialog'),
      title: Text(widget.title),
      content: Text(widget.body),
      actions: [
        TextButton(
          key: const ValueKey('expense_confirm_delete_cancel'),
          onPressed: _submitted ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('expense_confirm_delete_confirm'),
          onPressed: _submitted ? null : _confirm,
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
