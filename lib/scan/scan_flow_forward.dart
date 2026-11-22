part of 'scan_flow.dart';

/// v0.8.17: the scan-to-email forward action (Lane 2 interim route, the
/// locked contract with the recognition lane). The action lands right
/// after upload so app-user scans have a path to the lane while the
/// automated transport is pending:
/// - the photos ride as attachments in upload order, with a body line
///   pinning the order ("photo 1/N, 2/N, ...");
/// - the venue and the typed notes ride in the body;
/// - the scan ID names the subject line;
/// - APK hands the package to the native share sheet with the photos
///   attached;
/// - web opens a real email compose (mailto:) with the subject and body
///   prefilled - browsers cannot attach files to a share intent, so the
///   photos are attached by the user in upload order, and a clipboard
///   copy is the fallback when the compose cannot open;
/// - the flow ends on honest labeling - renders and the recognized item
///   list arrive by email, so nothing spins.
///
/// v0.8.17: the recipient was user-addressed only (the repo is public).
/// v0.8.19 (steward ruling): the receive mailbox address is published -
/// the web compose opens pre-addressed to afantashoon@gmail.com and the
/// labeling names the destination (which also covers the APK share path,
/// where a recipient cannot be prefilled). The coach's receive mailbox
/// watches for the subject pattern.
/// v0.8.20: the web labeling names the paperclip step explicitly -
/// browsers cannot attach photos for the user, so the label says to add
/// them in the email window in upload order, then send (the first live
/// scan went out with zero attachments because the step was only
/// implied).
/// v0.8.21: the web primary path hands the photos plus the prefilled
/// email text to the browser's Web Share API (the share sheet opens
/// with the photos already attached on supporting browsers); the
/// prefilled mailto compose stays as the fallback.
/// v0.8.29 (route B, steward ruling): the package rides to BOTH
/// processing lanes in one send - the coach's receive mailbox (renders +
/// the item list) and the recognition mailbox (the tiered read). The
/// recipients carry as one shared constant list: the mailto fallback
/// pre-addresses both, and every labeling line names both. The payload
/// format and the subject pattern are unchanged, so both mailboxes keep
/// filtering on the same subject.

/// v0.8.29: the forward package's recipients - both processing lanes in
/// one package. The coach's mailbox returns the renders and the item
/// list; the recognition mailbox returns the tiered read.
const String forwardRecipientCellulose = 'afantashoon@gmail.com';
const String forwardRecipientRecognition = 'chlorophyll@hellominds.ai';
const String forwardRecipients =
    '$forwardRecipientCellulose,$forwardRecipientRecognition';

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
/// line the chat shows once the package is handed off - the flow ends
/// there, no spinner, per the locked Lane 2 contract.
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
  if (kIsWeb) {
    // v0.8.21 web primary path: the Web Share API hands the photos and
    // the prefilled email text to the browser's share sheet - on
    // supporting browsers the compose opens with the photos already
    // attached (add the recipients and send). The prefilled mailto
    // compose (v0.8.19/20) stays as the fallback for browsers without
    // Web Share Level 2.
    final bool shared = await sharePhotosViaWebShare(
      bytes: photoBytes,
      mimes: photoMimes,
      subject: subject,
      body: body,
    );
    if (shared) {
      return 'Share sheet opened - the scanned photos are already '
          'attached. Pick your email app, add both processing lanes as '
          'the recipients - $forwardRecipientCellulose (the coach\'s '
          'receive mailbox, renders + item list) and '
          '$forwardRecipientRecognition (the recognition mailbox) - then '
          'press Send. Renders and the recognized item list arrive by '
          'email.';
    }
    // Web fallback: open a real email compose with the package prefilled
    // and pre-addressed to both processing lanes (v0.8.29). The photos
    // ride by hand (browsers cannot attach files for us), so the
    // labeling says exactly that - the paperclip step is named
    // explicitly, since the implied version was missed on the first
    // live scan.
    final String mailto =
        'mailto:$forwardRecipients?subject=${Uri.encodeComponent(subject)}'
        '&body=${Uri.encodeComponent(body)}';
    try {
      openMailCompose(Uri.parse(mailto));
      return 'Email compose opened - addressed to both processing lanes '
          '($forwardRecipientCellulose + $forwardRecipientRecognition). '
          'Browsers cannot attach the photos for you: tap the paperclip '
          'in the email window, add the scanned photos in upload order '
          '(photo 1 first), then press Send. Renders and the recognized '
          'item list arrive by email.';
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: body));
      return 'This browser could not open an email compose - the package '
          'body is copied. Paste it into an email addressed to '
          '$forwardRecipientCellulose and $forwardRecipientRecognition '
          '(both processing lanes), attach the photos by hand in upload '
          'order (photo 1 first), then send.';
    }
  }
  final List<XFile> files = _forwardFiles(photoBytes, photoMimes);
  await Share.shareXFiles(files, subject: subject, text: body);
  return 'Package sent - renders and the recognized item list arrive by email.';
}