/// Build the `mailto:` URL for the reminder's plain-text channel. The body joins the
/// signature/disclosure/quote fragments the draft returned around the user's edited
/// core (parity with the web) — formatting doesn't travel through mailto. Pure and
/// testable; percent-encoding uses component semantics so `&`/`=`/spaces survive.
String reminderMailtoUrl({
  required String address,
  required String subject,
  required String prefix,
  required String body,
  required String suffix,
}) {
  final parts = <String>[
    prefix,
    body,
    suffix,
  ].where((s) => s.trim().isNotEmpty);
  final joined = parts.join('\n\n');
  final addr = Uri.encodeComponent(address);
  final subj = Uri.encodeComponent(subject);
  final b = Uri.encodeComponent(joined);
  return 'mailto:$addr?subject=$subj&body=$b';
}
