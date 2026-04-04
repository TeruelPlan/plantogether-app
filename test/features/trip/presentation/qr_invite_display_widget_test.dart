import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantogether_app/features/trip/presentation/widgets/qr_invite_display_widget.dart';

void main() {
  group('QRInviteDisplayWidget', () {
    testWidgets('renders QR code and trip name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QRInviteDisplayWidget(
              inviteUrl: 'http://localhost/join?token=abc',
              tripName: 'Beach Weekend',
            ),
          ),
        ),
      );

      expect(find.text('Beach Weekend'), findsOneWidget);
    });

    testWidgets('has copy link button with tooltip', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QRInviteDisplayWidget(
              inviteUrl: 'http://localhost/join?token=abc',
              tripName: 'Test',
            ),
          ),
        ),
      );

      expect(find.byTooltip('Copy link'), findsOneWidget);
    });

    testWidgets('has share button with tooltip', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QRInviteDisplayWidget(
              inviteUrl: 'http://localhost/join?token=abc',
              tripName: 'Test',
            ),
          ),
        ),
      );

      expect(find.byTooltip('Share'), findsOneWidget);
    });

    testWidgets('has accessibility semantics for QR code', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QRInviteDisplayWidget(
              inviteUrl: 'http://localhost/join?token=abc',
              tripName: 'Beach Weekend',
            ),
          ),
        ),
      );

      final semantics = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label == 'QR code to join trip Beach Weekend',
      );
      expect(semantics, findsOneWidget);
    });
  });
}
