part of 'scan_flow.dart';

/// v0.8.7: recognition-intake flow members on the scan state. The coach
/// chat waits for the recognition lane's object list (interim route) and
/// drafts its plan from what was pasted in.
///
/// v0.8.5 pasted ONE list for the whole scan, so every angle after the
/// first went unread - the app appeared to consider only the first
/// uploaded image. Now each uploaded photo gets its own paste step,
/// matching the lane's per-image reads and the one-slot-per-angle render
/// gallery. The dialog also tracks the visual viewport, so on iOS Safari
/// it jumps above the keyboard and the input box shrinks while typing.
extension _ScanRecognitionFlow on _ScanFlowScreenState {
  void _buildAwaitingChat() {
    final int count = _photos.length;
    final List<_ChatLine> lines = <_ChatLine>[
      _ChatLine(
        text: count > 1
            ? 'These are the $count photos I am looking at.'
            : 'This is the photo I am looking at.',
        isPhoto: true,
      ),
      const _ChatLine(
        text: 'Photos received. I have not read this space yet - the '
            'recognition lane has not sent labels for this scan.',
      ),
      const _ChatLine(
        text: 'Paste the recognized object list for each photo and I will '
            'coach you from what is actually in the room.',
        isPasteAction: true,
      ),
      // v0.8.17: the Lane 2 interim route - the forward action sits
      // beside the paste fallback so a scan always has a path to the
      // recognition lane, hands-free or manual.
      const _ChatLine(
        text: 'Or forward this scan to the coach by email - the renders '
            'and the recognized item list come back the same way.',
        isForwardAction: true,
      ),
    ];
    _setUiState(() {
      _lines = lines;
      _revealed = lines.length;
      _stage = _ScanStage.chat;
    });
    _scrollToBottom();
  }

  /// Paste intake for the recognition lane lists (interim route), one
  /// dialog per uploaded photo. Skip leaves an angle without labels;
  /// Cancel aborts the whole intake so nothing half-lands.
  Future<void> _openRecognitionPaste() async {
    final List<_RecognizedObject> merged = <_RecognizedObject>[];
    for (int i = 0; i < _photos.length; i++) {
      final String angle = i == 0 ? 'Main view' : 'Angle ${i + 1}';
      final _AnglePaste? paste = await _pasteListDialog(
        'Recognized objects - $angle (photo ${i + 1} of ${_photos.length})',
      );
      if (!mounted) return;
      if (paste == null) return;
      merged.addAll(paste.items);
    }
    if (merged.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No object labels found in any of the lists'),
        ),
      );
      return;
    }
    _setUiState(() {
      _plan = _recognitionPlan(merged, _notesController.text.trim())
          .withVenue(_scanVenue);
      // v0.8.16: the merged list is kept so the scan's leave-behinds
      // can turn the confirmed and verify objects into unpacked items
      // on the venue's page.
      _recognized = merged;
      _awaitingRecognition = false;
    });
    _buildChatLines();
  }

  /// One keyboard-aware paste dialog. Returns null when cancelled; a
  /// skipped angle returns an empty list.
  Future<_AnglePaste?> _pasteListDialog(String title) async {
    final TextEditingController controller = TextEditingController();
    final ValueNotifier<double> keyboardInset = ValueNotifier<double>(0);
    final void Function() cancelInset =
        watchWebKeyboardInset((double inset) => keyboardInset.value = inset);
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => ValueListenableBuilder<double>(
        valueListenable: keyboardInset,
        builder: (BuildContext context, double inset, _) => AlertDialog(
          scrollable: true,
          alignment: inset > 0 ? Alignment.topCenter : Alignment.center,
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('One object per line with its confidence:'),
              const SizedBox(height: 6),
              const Text('loose papers - 92%'),
              const Text('notebooks - 60%'),
              const Text('collar tag - 40%'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                minLines: 2,
                maxLines: inset > 0 ? 4 : 8,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Paste the list from the recognition lane',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          // v0.8.9: the action buttons hide while the keyboard is up so
          // the input box keeps its height instead of compressing away.
          actions: inset > 0
              ? const <Widget>[]
              : <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(null),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Skip this angle'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text('Coach from this'),
                  ),
                ],
        ),
      ),
    );
    cancelInset();
    final String raw = controller.text;
    controller.dispose();
    keyboardInset.dispose();
    if (!mounted) return null;
    if (ok == null) return null;
    if (!ok) return const _AnglePaste();
    final List<_RecognizedObject> items = _parseRecognition(raw);
    return _AnglePaste(items);
  }
}

/// One angle's pasted recognition result (empty when the angle was skipped).
class _AnglePaste {
  const _AnglePaste([this.items = const <_RecognizedObject>[]]);

  final List<_RecognizedObject> items;
}
