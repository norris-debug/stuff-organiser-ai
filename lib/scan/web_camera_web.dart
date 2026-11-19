import 'dart:convert';
// dart:html is deprecated but still fully supported for Flutter 3.29 web
// builds; swap to package:web + dart:js_interop in a later cleanup pass.
// ignore: deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

class _WebCameraSheet extends StatefulWidget {
  const _WebCameraSheet({this.onFallback});

  final VoidCallback? onFallback;

  @override
  State<_WebCameraSheet> createState() => _WebCameraSheetState();
}

class _WebCameraSheetState extends State<_WebCameraSheet> {
  int _viewSeq = 0;
  String get _viewId =>
      'web-camera-${DateTime.now().millisecondsSinceEpoch}-$_viewSeq';

  html.MediaStream? _stream;
  html.VideoElement? _video;
  bool _starting = true;
  String? _problem;
  bool _front = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    final html.MediaStream? stream = _stream;
    if (stream != null) {
      stream.getTracks().forEach((track) => track.stop());
    }
    super.dispose();
  }

  Future<void> _start() async {
    try {
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
      final html.MediaStream stream = await devices.getUserMedia(
        <String, dynamic>{
          'audio': false,
          'video': <String, dynamic>{'facingMode': _front ? 'user' : 'environment'},
        },
      );
      if (!mounted) {
        stream.getTracks().forEach((track) => track.stop());
        return;
      }
      final html.VideoElement video = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..setAttribute('playsinline', 'true')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..srcObject = stream;
      final html.DivElement container = html.DivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..append(video);
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
        _viewId,
        (int viewId) => container,
      );
      setState(() {
        _stream = stream;
        _video = video;
        _starting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _problem = 'Camera permission was refused or no camera is available '
            'here. Allow camera access for this page, or use upload instead.';
      });
    }
  }

  /// Stops the current stream and reopens the camera facing the other way.
  Future<void> _flip() async {
    final html.MediaStream? stream = _stream;
    if (stream != null) {
      stream.getTracks().forEach((track) => track.stop());
    }
    setState(() {
      _stream = null;
      _video = null;
      _viewSeq++;
      _front = !_front;
      _starting = true;
      _problem = null;
    });
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
                        : HtmlElementView(viewType: _viewId),
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
