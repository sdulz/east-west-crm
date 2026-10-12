import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Phone / SMS / WhatsApp hand-off to the device (FR-MOB-016).
enum ContactChannel { call, sms, whatsapp }

Uri contactUri(ContactChannel channel, String phone) {
  final digits = phone.replaceAll(RegExp('[^0-9+]'), '');
  return switch (channel) {
    ContactChannel.call => Uri(scheme: 'tel', path: digits),
    ContactChannel.sms => Uri(scheme: 'sms', path: digits),
    // wa.me wants the international number without "+" or leading zeros.
    ContactChannel.whatsapp => Uri.https(
      'wa.me',
      '/${digits.replaceFirst(RegExp('^[+]'), '').replaceFirst(RegExp('^0+'), '')}',
    ),
  };
}

Future<void> openContact(
  BuildContext context,
  ContactChannel channel,
  String phone,
) async {
  final l = context.l10n;
  final label = switch (channel) {
    ContactChannel.call => l.call,
    ContactChannel.sms => l.message,
    ContactChannel.whatsapp => l.whatsapp,
  };
  final ok = await launchUrl(
    contactUri(channel, phone),
    mode: LaunchMode.externalApplication,
  ).catchError((_) => false);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l.couldNotOpen(label))));
  }
}

/// Three tonal buttons: Call · Message · WhatsApp.
class ContactButtons extends StatelessWidget {
  const ContactButtons({required this.phone, super.key});
  final String phone;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget button(Key key, Widget icon, String label, ContactChannel c) =>
        Expanded(
          child: FilledButton.tonalIcon(
            key: key,
            onPressed: () => openContact(context, c, phone),
            icon: icon,
            label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        );
    return Row(
      spacing: 8,
      children: [
        button(
          const Key('contact_call'),
          const Icon(Icons.call_outlined, size: 20),
          l.call,
          ContactChannel.call,
        ),
        button(
          const Key('contact_sms'),
          const Icon(Icons.sms_outlined, size: 20),
          l.message,
          ContactChannel.sms,
        ),
        button(
          const Key('contact_whatsapp'),
          const FaIcon(
            FontAwesomeIcons.whatsapp,
            size: 20,
            color: Color(0xFF25D366), // brand green
          ),
          l.whatsapp,
          ContactChannel.whatsapp,
        ),
      ],
    );
  }
}
