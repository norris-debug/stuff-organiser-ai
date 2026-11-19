/// Keyboard inset facade.
///
/// On the web build this resolves to the visualViewport based listener
/// (web_keyboard_web.dart): iOS Safari overlays the keyboard without
/// resizing the page, so Flutter never sees a view inset there. On every
/// other platform the stub is used and the framework viewInsets already
/// apply.
export 'web_keyboard_stub.dart' if (dart.library.html) 'web_keyboard_web.dart';
