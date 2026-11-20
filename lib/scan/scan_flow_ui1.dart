part of 'scan_flow.dart';

extension _ScanPickUi on _ScanFlowScreenState {
  Widget _buildPick(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool hasPhotos = _photos.isNotEmpty;
    final bool canAddMore = _photos.length < _maxPhotos;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: <Widget>[
        Center(
          child: MascotWidget(
            variant: widget.mascot,
            pack: widget.pack,
            size: 120,
            mood: MascotMood.happy,
            celebrationTick: 0,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Scan your space',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Photograph a messy table, desk, shelf, floor, bed or counter. Add '
          'up to six photos in total - extra angles welcome, so open the '
          'drawer or lift the pile - and type or dictate anything the camera '
          'cannot see. Nothing is analysed until you tap Next.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text(
          'Where are you tidying?',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _venueController,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 1,
          decoration: const InputDecoration(
            hintText: 'e.g. dining room, bedroom, living room',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final String venue in <String>[
              'Dining room',
              'Bedroom',
              'Living room',
            ])
              ActionChip(
                label: Text(venue),
                onPressed: () => _venueController.text = venue,
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (hasPhotos) ...<Widget>[
          _photoStrip(context),
          const SizedBox(height: 12),
        ],
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.icon(
                onPressed: (_analyzing || !canAddMore) ? null : _captureCamera,
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(hasPhotos ? 'Add photo' : 'Camera'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: (_analyzing || !canAddMore) ? null : _pickFromGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(hasPhotos ? 'Add from gallery' : 'Gallery'),
              ),
            ),
          ],
        ),
        // v0.8.25 (QA): debug-only affordance - with the ?semantics=1 test
        // mode on, automation can load bundled sample photos instead of
        // driving the native file chooser (which the CanvasKit browser
        // cannot). Nothing renders for normal users, not even spacing.
        if (soaiDebugMode) ...<Widget>[
          const SizedBox(height: 10),
          SamplePhotosDebugButton(onInject: _injectSamplePhotos),
        ],
        if (hasPhotos) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            '${_photos.length} of $_maxPhotos photos. The first one is the main view.',
            style: theme.textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 14),
        Text(
          'Type to the AI (optional) - anything the camera cannot see, for '
          'example what is under the pile.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _notesController,
                minLines: 1,
                maxLines: 3,
                maxLength: 600,
                decoration: InputDecoration(
                  hintText: 'e.g. socks under the clothes in the drawer',
                  counterText: '',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: 'Dictate notes',
                    icon: Icon(
                      _listening ? Icons.mic : Icons.mic_none,
                      color: _listening ? theme.colorScheme.primary : null,
                    ),
                    onPressed: _toggleDictation,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // v0.8.24 (Meiosis R4): the disabled Next must expose its
            // enabled state to the semantics tree - screen readers and
            // automation read the distinction at zero photos / while
            // analysing.
            Semantics(
              enabled: !_analyzing && hasPhotos,
              child: FilledButton.icon(
                onPressed:
                    (_analyzing || !hasPhotos) ? null : _confirmAndAnalyse,
                icon: const Icon(Icons.task_alt),
                label: Text(_analyzing ? 'Analysing...' : 'Next'),
              ),
            ),
          ],
        ),
        if (_listening) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            'Listening... tap the mic to stop.',
            style: theme.textTheme.bodySmall,
          ),
        ],
        if (_analyzing) ...<Widget>[
          const SizedBox(height: 20),
          RenderLoader(mascot: widget.mascot, pack: widget.pack),
        ],
        if (_error != null) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _photoStrip(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _photos.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 10),
        itemBuilder: (BuildContext context, int index) {
          final _PhotoItem photo = _photos[index];
          return Stack(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  photo.bytes,
                  width: 104,
                  height: 104,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: InkWell(
                  onTap: () => _removePhoto(index),
                  customBorder: const CircleBorder(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withAlpha(230),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              if (index == 0)
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Main',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// v0.8.25 (QA): appends the bundled sample photos to the queue in one
  /// rebuild, respecting the room left under the cap.
  void _injectSamplePhotos() {
    final int room = _maxPhotos - _photos.length;
    if (room <= 0) return;
    final List<Uint8List> samples = loadSamplePhotoBytes();
    final List<_PhotoItem> picked = <_PhotoItem>[
      for (final Uint8List bytes in samples.take(room))
        _PhotoItem(bytes: bytes, mime: 'image/png'),
    ];
    if (picked.isEmpty) return;
    _setUiState(() {
      _photos = <_PhotoItem>[..._photos, ...picked];
      _error = null;
    });
  }
}
