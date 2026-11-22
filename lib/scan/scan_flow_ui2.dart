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
    // v0.8.9: while the reply keyboard is up the bottom action button
    // hides, so the reply field keeps its height instead of compressing.
    final bool keyboardUp = MediaQuery.of(context).viewInsets.bottom > 0;
    final bool hideButtons = keyboardUp && _showChatReplyBar;
    // v0.8.14: the Show my tidy plan button is gone per the steward
    // directive - finishing the coach's reveal flows straight into the
    // tidy plan page (see _maybeFinishChatReveal), so the tidying
    // suggestion is always delivered in the chat first. The paste
    // fallback stays as the quiet inline link inside the waiting bubble.
    Widget? actionButton;
    if (!hideButtons && !allRevealed) {
      actionButton = OutlinedButton.icon(
        onPressed: _revealNext,
        icon: const Icon(Icons.arrow_downward),
        label: const Text('Next'),
      );
    }
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView.builder(
            controller: _chatScroll,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            itemCount: visible.length,
            itemBuilder: (BuildContext context, int index) => Semantics(
              // v0.8.28 (R7-F2 retarget): the reveal sequence carries
              // the live region - run #20 measured the coach output as
              // tap-gated (lines built instantly, no multi-minute
              // wait), so the plan is announced line by line as Next
              // reveals it. The flag rides only the newest revealed
              // line: each tap announces exactly one new line and
              // older nodes never re-announce.
              liveRegion: index == visible.length - 1,
              child: _bubble(context, visible[index]),
            ),
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
                if (_showChatReplyBar) _chatReplyBar(context),
                if (actionButton != null) actionButton,
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// v0.8.9: the reply bar for coach confirmation points. Submits on the
  /// send key or the send button; the answer lands as a user bubble.
  Widget _chatReplyBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _chatReplyController,
              onSubmitted: (_) => _submitChatReply(),
              textInputAction: TextInputAction.send,
              decoration: const InputDecoration(
                labelText: 'Reply to the coach',
                isDense: true,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Send reply',
            onPressed: _submitChatReply,
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }

  Widget _bubble(BuildContext context, _ChatLine line) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    // v0.8.7: the photo bubble shows EVERY uploaded angle as a labelled
    // strip. The old single-image bubble showed only the first photo,
    // which read as the app ignoring the rest of the scan.
    if (line.isPhoto) {
      if (_photos.isEmpty) return const SizedBox.shrink();
      return Align(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            height: 142,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: _photos.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(width: 8),
              itemBuilder: (BuildContext context, int index) {
                final _PhotoItem photo = _photos[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        photo.bytes,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      index == 0 ? 'Main' : 'Angle ${index + 1}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                );
              },
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
          Flexible(
            child: _awaitingRecognition && line.isPasteAction
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      bubble,
                      // v0.8.11: quiet inline paste fallback - the scan
                      // can't dead-end while the interim manual route is
                      // the only transport for the recognition list.
                      TextButton.icon(
                        onPressed: _openRecognitionPaste,
                        icon: const Icon(Icons.paste_rounded, size: 18),
                        label: const Text('Paste recognized list'),
                      ),
                    ],
                  )
                : _awaitingRecognition && line.isForwardAction
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          bubble,
                          // v0.8.17: the Lane 2 interim route - the
                          // forward action hands the photos, venue, notes
                          // and scan ID to the email app; the labeling
                          // line lands when the intent is handed off, so
                          // nothing spins.
                          TextButton.icon(
                            onPressed: _forwardScan,
                            icon: const Icon(Icons.forward_to_inbox_rounded,
                                size: 18),
                            label: const Text('Forward scan by email'),
                          ),
                        ],
                      )
                    : bubble,
          ),
        ],
      ),
    );
  }

  /// v0.8.17: hands the current scan's photos, venue and notes to the
  /// email app as the Lane 2 forward package (scan_flow_forward.dart).
  /// The honest labeling line lands as a coach line when the intent is
  /// handed off - the flow ends there, no spinner.
  Future<void> _forwardScan() async {
    if (_photos.isEmpty) return;
    final String labeling = await launchForwardPackage(
      photoBytes: _photos.map((_PhotoItem p) => p.bytes).toList(),
      photoMimes: _photos.map((_PhotoItem p) => p.mime).toList(),
      venue: _scanVenue,
      notes: _notesController.text.trim(),
      scanId: _newScanId(),
    );
    if (!mounted) return;
    _setUiState(() {
      _lines = <_ChatLine>[..._lines, _ChatLine(text: labeling)];
      _revealed = _lines.length;
    });
    _scrollToBottom();
  }
}