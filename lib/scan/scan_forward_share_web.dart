// ignore_for_file: deprecated_member_use

/// Web implementation (v0.8.21): hands the photos plus the prefilled
/// email text to the browser's Web Share API. On browsers that support
/// sharing files (Web Share Level 2) the OS share sheet opens with the
/// photos already attached - picking an email app then opens a compose
/// with the photos in place. Returns true when the share sheet took the
/// handoff; false when the API is missing, the payload cannot be
/// shared, or the call fails - the caller falls back to the prefilled
/// mailto compose.
import 'dart:html' as html;
import 'dart:js_util' as js;
import 'dart:typed_data';

/// True when this browser exposes the Web Share API with file support.
bool webShareFilesSupported() {
  final dynamic nav = html.window.navigator;
  try {
    return js.hasProperty(nav, 'share') && js.hasProperty(nav, 'canShare');
  } catch (_) {
    return false;
  }
}

Future<bool> sharePhotosViaWebShare({
  required List<Uint8List> bytes,
  required List<String> mimes,
  required String subject,
  required String body,
}) async {
  try {
    if (!webShareFilesSupported()) return false;
    // Raw JS construction: dart:html's File wrapper does not expose a
    // 'type' named parameter, so build the exact platform shape here -
    // new File([blob], name, {type}) - via js_util instead.
    final dynamic fileCtor = js.getProperty(html.window, 'File');
    final List<dynamic> files = <dynamic>[];
    for (int i = 0; i < bytes.length && i < mimes.length; i++) {
      final String ext = mimes[i].contains('png') ? 'png' : 'jpg';
      final html.Blob blob = html.Blob(<Object>[bytes[i]], mimes[i]);
      files.add(js.callConstructor(fileCtor, <dynamic>[
        <dynamic>[blob],
        'photo-${i + 1}.$ext',
        js.jsify(<String, dynamic>{'type': mimes[i]}),
      ]));
    }
    final Object payload = js.jsify(<String, dynamic>{
      'title': subject,
      'text': body,
      'files': files,
    });
    final Object? allowed =
        js.callMethod(html.window.navigator, 'canShare', <dynamic>[payload]);
    if (allowed != true) return false;
    await js.promiseToFuture<Object?>(
        js.callMethod(html.window.navigator, 'share', <dynamic>[payload]));
    return true;
  } catch (error) {
    // A user-cancelled share sheet (AbortError) is not a failure - the
    // handoff happened and the user chose to stop. Falling back to the
    // mailto compose after an explicit cancel would double-prompt.
    if (error.toString().toLowerCase().contains('abort')) return true;
    return false;
  }
}
