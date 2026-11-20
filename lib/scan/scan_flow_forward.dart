part of 'scan_flow.dart';

/// v0.8.17: the scan-to-email forward action (Lane 2 interim route, the
/// locked contract with the recognition lane). The action lands right
/// after upload so app-user scans have a path to the lane while the
/// automated transport is pending:
/// - the photos ride as attachments in upload order, with a body line
///   pinning the order ("photo 1/N, 2/N, ...");
/// - the venue and the typed notes ride in the body;
/// - the scan ID names the subject line;
/// - APK shares the package natively; web uses the browser share sheet
///   where it supports files and falls back to a copied body where it
///   does not (honest about that edge);
/// - the flow ends on the "package sent" labeling - renders and the
///   recognized item list arrive by email, so nothing spins.
///
/// The recipient is intentionally NOT hardcoded: the user addresses the
/// email themselves (the repo is public - no private address belongs in
/// source). The coach's receive mailbox watches for the subject pattern.

/// The attached photos as share files, named in upload order.
List<XFile> _forwardFiles(List<Uint8List> bytes, List<String> mimes) {
  final List<XFile> files = <XFile>[];
  for (int i = 0; i < bytes.length && i < mimes.length; i++) {
    final String ext = mimes[i].contains('png') ? 'png' : 'jpg';
    files.add(XFile.fromData(
      bytes[i],
      mimeType: mimes[i],
      name: 'photo-${i + 1}.$ext',
    ));
  }
  return files;
}

/// The email subject: the scan ID names the batch.
String forwardSubject(String scanId) => 'Stuff Organiser scan $scanId';

/// The email body: order pinned, venue, typed notes.
String forwardBody({
  required int photoCount,
  required String venue,
  required String notes,
  required String scanId,
}) {
  final StringBuffer buffer = StringBuffer();
  buffer
      .writeln('Scan $scanId - $photoCount photo(s) attached in upload order:');
  for (int i = 0; i < photoCount; i++) {
    buffer.writeln('photo ${i + 1}/$photoCount');
  }
  buffer.writeln('Venue: ${venue.isEmpty ? '(not set)' : venue}');
  buffer.writeln('Notes: ${notes.isEmpty ? '(none)' : notes}');
  buffer.writeln();
  buffer.writeln(
      'Sent from Stuff Organiser AI. Renders and the recognized item list '
      'arrive by email.');
  return buffer.toString();
}

/// v0.8.17: launches the forward package for one scan. Public so the
/// awaiting-bubble UI can call it directly. Returns the honest labeling
/// line the chat shows once the share intent is handed off - the flow
/// ends there, no spinner, per the locked Lane 2 contract.
Future<String> launchForwardPackage({
  required List<Uint8List> photoBytes,
  required List<String> photoMimes,
  required String venue,
  required String notes,
  required String scanId,
}) async {
  final String subject = forwardSubject(scanId);
  final String body = forwardBody(
    photoCount: photoBytes.length,
    venue: venue,
    notes: notes,
    scanId: scanId,
  );
  final List<XFile> files = _forwardFiles(photoBytes, photoMimes);
  if (kIsWeb) {
    // Web: the browser share sheet when it supports files; a copied
    // body where it does not, so the scan still reaches the lane.
    try {
      await Share.shareXFiles(files, subject: subject, text: body);
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: body));
      return 'This browser could not attach the photos - the package body is '
          'copied. Paste it into an email to the coach and attach the photos '
          'in upload order (photo 1 first).';
    }
  } else {
    await Share.shareXFiles(files, subject: subject, text: body);
  }
  return 'Package sent - renders and the recognized item list arrive by email.';
}
