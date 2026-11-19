import 'dart:async';
// dart:html is deprecated but still fully supported for Flutter 3.29 web
// builds; swap to package:web + dart:js_interop in a later cleanup pass.
// ignore: deprecated_member_use
import 'dart:html' as html;

/// Fires [onChanged] with the current keyboard inset whenever the visual
/// viewport resizes or scrolls. iOS Safari overlays the keyboard without
/// resizing the page, so the inset is the gap between the layout viewport
/// (window.innerHeight) and the visible viewport (visualViewport.height).
/// Returns a function that removes the listeners again.
void Function() watchWebKeyboardInset(
  void Function(double inset) onChanged,
) {
  void read() {
    final num? inner = html.window.innerHeight;
    final num? visible = html.window.visualViewport?.height;
    if (inner == null || visible == null) return;
    final double raw = inner.toDouble() - visible.toDouble();
    final double inset = raw < 0 ? 0 : raw;
    onChanged(inset);
  }

  read();
  final StreamSubscription<dynamic>? resizeSub =
      html.window.visualViewport?.onResize.listen((_) => read());
  final StreamSubscription<dynamic>? scrollSub =
      html.window.visualViewport?.onScroll.listen((_) => read());
  return () {
    resizeSub?.cancel();
    scrollSub?.cancel();
  };
}
