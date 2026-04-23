import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart' show Share;

class QRInviteDisplayWidget extends StatelessWidget {
  final String inviteUrl;
  final String tripName;

  const QRInviteDisplayWidget({
    super.key,
    required this.inviteUrl,
    required this.tripName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Semantics(
          label: 'QR code to join trip $tripName',
          child: QrImageView(
            data: inviteUrl,
            version: QrVersions.auto,
            size: 256,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          tripName,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              key: const ValueKey('invite_copy_link_button'),
              icon: const Icon(Icons.copy),
              tooltip: 'Copy link',
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: inviteUrl));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied!')),
                  );
                }
              },
            ),
            const SizedBox(width: 16),
            IconButton(
              key: const ValueKey('invite_share_button'),
              icon: const Icon(Icons.share),
              tooltip: 'Share',
              onPressed: () {
                Share.share(inviteUrl);
              },
            ),
          ],
        ),
      ],
    );
  }
}
