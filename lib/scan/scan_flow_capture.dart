part of 'scan_flow.dart';

extension _ScanCapture on _ScanFlowScreenState {
  /// One shot from the camera. The user can press the button again to add
  /// another photo until the cap is reached.
  Future<void> _captureCamera() async {
    if (_photos.length >= _maxPhotos) return;
    if (kIsWeb) {
      // The plugin camera path does not capture in browsers, so the web
      // build uses an in-app camera sheet built on getUserMedia instead.
      final XFile? file = await captureWithWebCamera(
        context,
        onFallback: _pickFromGallery,
      );
      if (file == null) return;
      final Uint8List bytes = await file.readAsBytes();
      if (!mounted) return;
      _setUiState(() {
        _photos = <_PhotoItem>[
          ..._photos,
          _PhotoItem(bytes: bytes, mime: 'image/jpeg'),
        ];
        _error = null;
      });
      return;
    }
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1280,
      );
      if (file == null) return;
      final Uint8List bytes = await file.readAsBytes();
      if (!mounted) return;
      _setUiState(() {
        _photos = <_PhotoItem>[
          ..._photos,
          _PhotoItem(bytes: bytes, mime: _mimeFor(file.path)),
        ];
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      _setUiState(() {
        _error = 'Could not open the camera or the gallery. Please try again.';
      });
    }
  }

  /// Several photos in one tap from the gallery. Whatever the picker returns
  /// is trimmed to the room left under the cap and added in a single rebuild.
  Future<void> _pickFromGallery() async {
    final int room = _maxPhotos - _photos.length;
    if (room <= 0) return;
    try {
      final List<XFile> files = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1280,
      );
      if (files.isEmpty) return;
      final List<XFile> selected = files.length > room
          ? files.sublist(0, room)
          : files;
      final List<_PhotoItem> picked = <_PhotoItem>[];
      for (final XFile file in selected) {
        try {
          final Uint8List bytes = await file.readAsBytes();
          if (!mounted) return;
          picked.add(_PhotoItem(bytes: bytes, mime: _mimeFor(file.path)));
        } catch (_) {
          // Skip a photo that cannot be read instead of losing the whole batch.
        }
      }
      if (picked.isEmpty) return;
      if (!mounted) return;
      _setUiState(() {
        _photos = <_PhotoItem>[..._photos, ...picked];
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      _setUiState(() {
        _error = 'Could not open the camera or the gallery. Please try again.';
      });
    }
  }

  void _removePhoto(int index) {
    if (index < 0 || index >= _photos.length) return;
    _setUiState(() {
      final List<_PhotoItem> remaining = <_PhotoItem>[..._photos];
      remaining.removeAt(index);
      _photos = remaining;
    });
  }

  String _mimeFor(String path) {
    final String lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }
}
