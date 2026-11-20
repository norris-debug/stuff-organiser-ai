/// Mailto handoff facade for the scan-to-email forward action.
///
/// On the web build this resolves to the dart:html based compose opener
/// (scan_forward_mailto_web.dart); every other platform gets the stub,
/// since the forward action only requests a mail compose under kIsWeb.
/// v0.8.21: the same facade re-exports the Web Share API handoff
/// (scan_forward_share_web.dart / scan_forward_share_stub.dart) so the
/// scan library keeps one conditional-import site for the forward
/// transport.
export 'scan_forward_mailto_stub.dart'
    if (dart.library.html) 'scan_forward_mailto_web.dart';
export 'scan_forward_share_stub.dart'
    if (dart.library.html) 'scan_forward_share_web.dart';
