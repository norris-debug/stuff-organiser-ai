// QA/debug tooling for Stuff Organiser AI (v0.8.25).
// Everything here is gated behind soaiDebugMode and must stay invisible to
// normal users: the flag only turns on with the ?semantics=1 test mode
// (main.dart shares that exact gate) or when a widget test sets it
// directly.
import 'package:flutter/material.dart';

/// Master QA/debug switch. Set once at startup from the semantics test
/// mode gate; widget tests may set it directly.
bool soaiDebugMode = false;

/// Debug-only affordance: injects the bundled sample photos into the scan
/// flow so photo-dependent stages (gallery strip, results, venue pages,
/// forward action) can be exercised by automation without the native file
/// chooser or camera permission. Renders nothing unless the debug flag is
/// on; the Semantics wrapper keeps it visible in the ARIA tree when it is.
class SamplePhotosDebugButton extends StatelessWidget {
  const SamplePhotosDebugButton({super.key, required this.onInject});

  /// Called on tap; the caller adds the sample photos to the scan flow's
  /// photo queue.
  final VoidCallback onInject;

  @override
  Widget build(BuildContext context) {
    if (!soaiDebugMode) {
      return const SizedBox.shrink();
    }
    return Semantics(
      label: 'Load sample photos (debug)',
      button: true,
      child: OutlinedButton.icon(
        key: const ValueKey<String>('qa_sample_photos_button'),
        onPressed: onInject,
        icon: const Icon(Icons.science_outlined),
        label: const Text('Load sample photos'),
      ),
    );
  }
}
