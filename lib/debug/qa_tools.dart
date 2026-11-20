// QA/debug + accessibility tooling for Stuff Organiser AI (v0.8.27).
// The debug members below stay gated behind soaiDebugMode and invisible
// to normal users: the flag only turns on with the ?semantics=1 test
// mode (main.dart shares that exact gate) or when a widget test sets it
// directly. SoaiSemanticsButton is production accessibility tooling: it
// renders nothing and changes no visuals - it exists so one control can
// expose exactly one accurate accessible node to screen readers and
// automation.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Master QA/debug switch. Set once at startup from the semantics test
/// mode gate; widget tests may set it directly.
bool soaiDebugMode = false;

/// v0.8.27 (Meiosis R6-F2 + R7-F1): render-level semantics host for a
/// button control. On this Flutter web build the engine writes
/// aria-disabled only when a semantics node carries the enabled-state
/// flag, and the widget-level paths never produce that flag: neither a
/// Semantics wrap (v0.8.24-v0.8.26, including the container:true role
/// merge) nor Material's native-disabled button node. This widget owns
/// the semantics boundary at the render level - the layer the engine
/// actually reads - as exactly ONE node carrying button role, label and
/// enabled state, with the tap action present only while enabled.
/// Wrap the real button in ExcludeSemantics so its own node drops out
/// and the tree stays single-node (the 0.8.26 wrapper serialized as a
/// second same-labeled button node).
///
/// Visually and for hit-testing this behaves like a plain wrapper: it
/// paints nothing and passes taps through to the child, which keeps the
/// real onPressed guard as the behavioral gate.
class SoaiSemanticsButton extends SingleChildRenderObjectWidget {
  const SoaiSemanticsButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onTap,
    super.child,
  });

  /// The control's accessible name. Keep it equal to the visible text.
  final String label;

  /// Whether the control is enabled. Always serialized as the node's
  /// enabled state (non-null = state present), so the ARIA tree shows
  /// the true state at zero photos and while analysing instead of a
  /// stateless enabled button.
  final bool enabled;

  /// Invoked for assistive-tech activation while enabled; the disabled
  /// node carries no tap action at all.
  final VoidCallback? onTap;

  @override
  RenderSoaiSemanticsButton createRenderObject(BuildContext context) {
    return RenderSoaiSemanticsButton(
      label: label,
      enabled: enabled,
      onTap: enabled ? onTap : null,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderSoaiSemanticsButton renderObject,
  ) {
    renderObject
      ..label = label
      ..enabled = enabled
      ..onTap = enabled ? onTap : null;
  }
}

/// Render object owning exactly one semantics node: button role, label,
/// enabled state and (while enabled) the tap action, which dispatches to
/// the same callback the inner button guards.
class RenderSoaiSemanticsButton extends RenderProxyBox {
  RenderSoaiSemanticsButton({
    required String label,
    required bool enabled,
    VoidCallback? onTap,
  })  : _label = label,
        _enabled = enabled,
        _onTap = onTap;

  String _label;
  String get label => _label;
  set label(String value) {
    if (_label == value) return;
    _label = value;
    markNeedsSemanticsUpdate();
  }

  bool _enabled;
  bool get enabled => _enabled;
  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    markNeedsSemanticsUpdate();
  }

  VoidCallback? _onTap;
  VoidCallback? get onTap => _onTap;
  set onTap(VoidCallback? value) {
    if (_onTap == value) return;
    final bool hadTap = _onTap != null;
    _onTap = value;
    if (hadTap != (value != null)) markNeedsSemanticsUpdate();
  }

  void _handleTap() => _onTap?.call();

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isSemanticBoundary = true;
    config.isButton = true;
    config.label = _label;
    // Non-null = the node carries the enabled-state flag - what the web
    // engine reads to emit aria-disabled="true" while disabled.
    config.isEnabled = _enabled;
    if (_enabled && _onTap != null) {
      config.onTap = _handleTap;
    }
  }
}

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
