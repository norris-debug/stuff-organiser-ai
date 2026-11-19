/// Non-web no-op: native platforms resize the window for the on-screen
/// keyboard, so the framework viewInsets already cover the fix and no
/// extra listener is needed.
void Function() watchWebKeyboardInset(
  void Function(double inset) onChanged,
) {
  return () {};
}
