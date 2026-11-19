part of 'scan_flow.dart';

/// v0.8.2: the tidied-up render for each uploaded angle, kept in scan
/// order. The Cellulose lane returns one organized render per angle; until
/// the automated lane wiring lands, each render is attached to its slot
/// from the lane's post-back. Cleared at the start of every analysis so a
/// new round never shows a previous round's renders.
final List<Uint8List?> _angleRenders = <Uint8List?>[];

extension _ScanChatResultUi on _ScanFlowScreenState {
  Widget _buildChat(BuildContext context) {
    final List<_ChatLine> visible = _lines.take(_revealed).toList();
    final bool allRevealed = _revealed >= _lines.length;
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView.builder(
            controller: _chatScroll,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            itemCount: visible.length,
            itemBuilder: (BuildContext context, int index) =>
                _bubble(context, visible[index]),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (allRevealed)
                  FilledButton.icon(
                    onPressed: _openResult,
                    icon: const Icon(Icons.checklist_rounded),
                    label: const Text('Show my tidy plan'),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _revealNext,
                    icon: const Icon(Icons.arrow_downward),
                    label: const Text('Next'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bubble(BuildContext context, _ChatLine line) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    if (line.isPhoto) {
      final Uint8List? bytes = _photos.isEmpty ? null : _photos.first.bytes;
      if (bytes == null) return const SizedBox.shrink();
      return Align(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(
              bytes,
              width: 220,
              height: 220,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }
    final bool isUser = line.isUser;
    final Widget bubble = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isUser ? scheme.primaryContainer : scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        line.text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color:
              isUser ? scheme.onPrimaryContainer : scheme.onSecondaryContainer,
          fontWeight: line.isHeading ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: bubble,
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: MascotWidget(
              variant: widget.mascot,
              pack: widget.pack,
              size: 36,
              celebrationTick: 0,
            ),
          ),
          Flexible(child: bubble),
        ],
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Uint8List? bytes = _photos.isEmpty ? null : _photos.first.bytes;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: bytes == null
                  ? Container(
                      width: 88,
                      height: 88,
                      color: theme.colorScheme.surfaceContainerHighest,
                    )
                  : Image.memory(
                      bytes,
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Your tidy plan',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_plan.suggestions.length} concrete actions for this space',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (_notesController.text.trim().isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      'Analysed ${_photos.length} photos plus your notes.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _chipsRow(context),
        const SizedBox(height: 14),
        _afterCard(context),
        const SizedBox(height: 14),
        _renderGalleryCard(context),
        const SizedBox(height: 14),
        _notesCard(context),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _saveThenNewRound,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Scan another room'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _saveThenHome,
                icon: const Icon(Icons.home_outlined),
                label: const Text('Return to homepage'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// v0.8.2: the cleaned-up room gallery - one slot per uploaded angle so
  /// the tidied-up views read together as one holistic picture.
  Widget _renderGalleryCard(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Cleaned-up room',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'One tidied-up render per angle. The Cellulose lane reads '
              'every photo you uploaded and returns the cleaned-up view '
              'for each - attach each render to its slot as it lands.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < _photos.length; i++) _renderSlot(context, i),
          ],
        ),
      ),
    );
  }

  Widget _renderSlot(BuildContext context, int index) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final _PhotoItem photo = _photos[index];
    final Uint8List? render = _renderAt(index);
    final String label = index == 0 ? 'Main view' : 'Angle ${index + 1}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  photo.bytes,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      render == null
                          ? 'Render pending from the Cellulose lane.'
                          : 'Tidied-up view for this angle.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (render == null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _pickRender(index),
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text('Attach the render for $label'),
              ),
            )
          else
            Stack(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    render,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: InkWell(
                    onTap: () => _removeRender(index),
                    customBorder: const CircleBorder(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: scheme.surface.withAlpha(230),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _pickRender(int index) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final Uint8List bytes = await picked.readAsBytes();
    if (!mounted) return;
    _setUiState(() {
      while (_angleRenders.length <= index) {
        _angleRenders.add(null);
      }
      _angleRenders[index] = bytes;
    });
  }

  void _removeRender(int index) {
    _setUiState(() {
      if (index < _angleRenders.length) {
        _angleRenders[index] = null;
      }
    });
  }

  Uint8List? _renderAt(int index) {
    if (index >= _angleRenders.length) return null;
    return _angleRenders[index];
  }

  Widget _chipsRow(BuildContext context) {
    final _ScanPlan plan = _plan;
    if (!plan.hasSetting && !plan.hasTidiness) {
      return const SizedBox.shrink();
    }
    final double maxWidth = MediaQuery.of(context).size.width - 48;
    final List<Widget> chips = <Widget>[];
    if (plan.hasSetting) {
      chips.add(
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Chip(
            avatar: const Icon(Icons.place_outlined, size: 18),
            label: Text(
              'Setting: ${plan.setting}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }
    if (plan.hasTidiness) {
      chips.add(
        Chip(
          avatar: const Icon(Icons.spa_outlined, size: 18),
          label: Text('Mess level: ${_titleCase(plan.tidiness)}'),
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }
}
