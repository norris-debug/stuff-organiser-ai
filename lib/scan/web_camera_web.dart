import 'dart:convert';
// dart:html is deprecated but still fully supported for Flutter 3.29 web
// builds; swap to package:web + dart:js_interop in a later cleanup pass.
// ignore: deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// v0.8.6: the browser camera session lives as module-level singletons so a
/// second capture reattaches the SAME live stream instead of running a
/// fresh getUserMedia. Acquiring the camera again right after stopping the
/// previous stream serves a dead/black frame on some browsers (notably iOS
/// Safari), which is what made the live preview vanish from the second
/// photo onward. The stream is fully released only when the scan flow
/// closes (releaseWebCamera).
html.MediaStream? _sessionStream;
html.VideoElement? _sessionVideo;
html.DivElement? _sessionContainer;
bool _sessionFront = false;

/// Opens an in-app camera sheet on the web using the browser getUserMedia
/// API. Returns the captured frame as an XFile, or null when the user
/// cancels or the camera cannot be opened.
Future<XFile?> captureWithWebCamera(
  BuildContext context, {
  VoidCallback? onFallback,
}) {
  return showModalBottomSheet<XFile?>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) =>
        _WebCameraSheet(onFallback: onFallback),
  );
}

/// Fully releases the shared camera session. Call when the screen that
/// opened the camera closes, so the browser camera indicator turns off.
void releaseWebCamera() {
  final html.MediaStream? stream = _sessionStream;
  _sessionStream = null;
  final html.VideoElement? video = _sessionVideo;
  if (video != null) {
    video.pause();
    video.srcObject = null;
  }
  _sessionVideo = null;
  _sessionContainer = null;
  _sessionFront = false;
  if (stream != null) {
    stream.getTracks().forEach((track) => track.stop());
  }
}

class _WebCameraSheet extends StatefulWidget {
  const _WebCameraSheet({this.onFallback});

  final VoidCallback? onFallback;

  @override
  State<_WebCameraSheet> createState() => _WebCameraSheetState();
}

class _WebCameraSheetState extends State<_WebCameraSheet> {
  int _viewSeq = 0;
  String? _activeViewId;

  html.VideoElement? _video;
  bool _starting = true;
  String? _problem;
  bool _front = _sessionFront;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    // Keep the shared session alive between captures - the next sheet open
    // reattaches the same live stream instead of asking the browser for a
    // fresh one (a fresh acquire right after a stop can serve a dead
    // frame). The scan flow releases it fully on close.
    final html.VideoElement? video = _sessionVideo;
    if (video != null) {
      video.pause();
    }
    super.dispose();
  }

  Future<void> _start() async {
    final html.MediaDevices? devices = html.window.navigator.mediaDevices;
    if (devices == null) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _problem =
            'This browser does not offer camera access. Use upload instead.';
      });
      return;
    }
    html.MediaStream? stream = _sessionStream;
    final bool sessionLive = stream != null &&
        stream.getVideoTracks().isNotEmpty &&
        _sessionFront == _front;
    if (!sessionLive) {
      _teardownSession();
      try {
        final html.MediaStream fresh = await devices.getUserMedia(
          <String, dynamic>{
            'audio': false,
            'video': <String, dynamic>{
              'facingMode': _front ? 'user' : 'environment',
            },
          },
        ).timeout(const Duration(seconds: 8));
        if (!mounted) {
          fresh.getTracks().forEach((track) => track.stop());
          return;
        }
        if (fresh.getVideoTracks().isEmpty) {
          fresh.getTracks().forEach((track) => track.stop());
          setState(() {
            _starting = false;
            _problem = 'No video feed came back from the camera. Use '
                'upload instead.';
          });
          return;
        }
        _sessionStream = fresh;
        _sessionFront = _front;
        stream = fresh;
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _starting = false;
          _problem = 'Camera could not start here (refused, busy or too '
              'slow). Allow camera access for this page, or use upload '
              'instead.';
        });
        return;
      }
    }
    // Reattach the shared preview element (same live stream on the second
    // and later opens) under a fresh view id, registered before the
    // preview widget builds.
    final html.VideoElement video = _sessionVideo ??= html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..setAttribute('playsinline', 'true')
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover';
    final html.DivElement container = _sessionContainer ??= html.DivElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..append(video);
    final html.MediaStream attached = stream;
    video.srcObject = attached;
    try {
      // Explicit play for browsers that skip autoplay on reattach; the
      // video is muted, so this never needs a gesture.
      video.play();
    } catch (_) {
      // Autoplay refusal is fine - the element is already live.
    }
    final String viewId =
        'web-camera-${DateTime.now().millisecondsSinceEpoch}-$_viewSeq';
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      viewId,
      (int viewId) => container,
    );
    if (!mounted) return;
    setState(() {
      _video = video;
      _activeViewId = viewId;
      _starting = false;
    });
  }

  /// Fully releases the shared session so the next acquire starts clean.
  void _teardownSession() {
    final html.VideoElement? video = _sessionVideo;
    if (video != null) {
      video.pause();
      video.srcObject = null;
    }
    final html.MediaStream? stream = _sessionStream;
    if (stream != null) {
      stream.getTracks().forEach((track) => track.stop());
    }
    _sessionStream = null;
    _sessionVideo = null;
    _sessionContainer = null;
  }

  /// Stops the current stream and reopens the camera facing the other way.
  Future<void> _flip() async {
    _teardownSession();
    setState(() {
      _video = null;
      _activeViewId = null;
      _viewSeq++;
      _front = !_front;
      _starting = true;
      _problem = null;
    });
    // Give the browser a beat to release the device before re-acquiring -
    // an instant re-open can serve a dead frame.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await _start();
  }

  Future<void> _grab() async {
    final html.VideoElement? video = _video;
    if (video == null || video.videoWidth == 0 || video.videoHeight == 0) {
      return;
    }
    try {
      final html.CanvasElement canvas = html.CanvasElement(
        width: video.videoWidth,
        height: video.videoHeight,
      );
      final html.CanvasRenderingContext2D ctx =
          canvas.getContext('2d') as html.CanvasRenderingContext2D;
      ctx.drawImage(video, 0, 0);
      final String dataUrl = canvas.toDataUrl('image/jpeg', 0.9);
      final int splitAt = dataUrl.indexOf(',');
      if (splitAt < 0) throw StateError('bad data url');
      final Uint8List bytes = base64Decode(dataUrl.substring(splitAt + 1));
      final XFile file = XFile.fromData(
        bytes,
        name: 'web-capture.jpg',
        mimeType: 'image/jpeg',
      );
      if (!mounted) return;
      Navigator.of(context).pop(file);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _problem = 'Could not save that capture. Try again, or use upload '
            'instead.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Take a photo',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'The browser camera opens here. Frame the space, then tap '
              'Capture to add it to your scan.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 320,
                child: _starting
                    ? const Center(child: CircularProgressIndicator())
                    : _problem != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                _problem!,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          )
                        : _activeViewId == null
                              ? const SizedBox.shrink()
                              : HtmlElementView(viewType: _activeViewId!),
              ),
            ),
            const SizedBox(height: 12),
            if (_problem == null)
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _grab,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Capture'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _starting ? null : _flip,
                    icon: const Icon(Icons.cameraswitch_outlined),
                    label: Text(_front ? 'Front' : 'Rear'),
                  ),
                ],
              )
            else if (widget.onFallback != null)
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onFallback!();
                },
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Use upload instead'),
              ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
