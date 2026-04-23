import 'package:flutter/material.dart';

/// Reusable persistent banner shown when a real-time stream is reconnecting
/// or otherwise offline. Designed to coexist with transient SnackBars.
class OfflineSyncBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismissed;

  const OfflineSyncBanner({super.key, required this.message, this.onDismissed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Reconnecting to live updates',
      child: Material(
        color: colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.wifi_off, color: colorScheme.onSecondaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: colorScheme.onSecondaryContainer),
                ),
              ),
              if (onDismissed != null)
                IconButton(
                  key: const ValueKey('offline_sync_dismiss_button'),
                  icon: Icon(Icons.close, color: colorScheme.onSecondaryContainer),
                  onPressed: onDismissed,
                  tooltip: 'Dismiss',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
