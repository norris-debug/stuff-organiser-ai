/// Mailto handoff facade for the scan-to-email forward action.
///
/// On the web build this resolves to the dart:html based compose opener
/// (scan_forward_mailto_web.dart); every other platform gets the stub,
/// since the forward action only requests a mail compose under kIsWeb.
export 'scan_forward_mailto_stub.dart'
    if (dart.library.html) 'scan_forward_mailto_web.dart';
