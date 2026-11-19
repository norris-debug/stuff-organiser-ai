part of 'scan_flow.dart';

extension _ScanChatFlow on _ScanFlowScreenState {
  void _buildChatLines() {
    final _ScanPlan plan = _plan;
    final String notes = _notesController.text.trim();
    final int photoCount = _photos.length;
    final List<_ChatLine> lines = <_ChatLine>[];
    lines.add(
      _ChatLine(
        text: photoCount > 1
            ? 'These are the $photoCount photos I am looking at.'
            : 'This is the photo I am looking at.',
        isPhoto: true,
      ),
    );
    lines.add(_ChatLine(text: _introLine()));
    if (notes.isNotEmpty) {
      lines.add(
        _ChatLine(
          text: 'You told me: ${_clip(notes, 140)} - I folded that into the plan.',
          isUser: true,
        ),
      );
    }
    for (final String observation in plan.observations) {
      lines.add(_ChatLine(text: observation));
    }
    for (int i = 0; i < plan.suggestions.length; i++) {
      final _Suggestion suggestion = plan.suggestions[i];
      lines.add(_ChatLine(text: suggestion.title, isHeading: true));
      if (suggestion.detail.isNotEmpty) {
        lines.add(_ChatLine(text: suggestion.detail));
      }
      if (suggestion.steps.isNotEmpty) {
        lines.add(_ChatLine(text: 'How to do it: ${suggestion.steps.join(' -> ')}'));
      }
      if (i < plan.suggestions.length - 1) {
        lines.add(
          _ChatLine(
            text: _interjections[i % _interjections.length],
            isUser: true,
          ),
        );
      }
    }
    lines.add(
      const _ChatLine(
        text: 'That is the whole plan. Start with the first action, then take '
            'another photo afterwards and we will check how the space looks.',
      ),
    );
    _setUiState(() {
      _lines = lines;
      _revealed = 1;
      _stage = _ScanStage.chat;
    });
    _scrollToBottom();
  }

  String _clip(String text, int max) {
    if (text.length <= max) return text;
    return '${text.substring(0, max)}...';
  }

  String _introLine() {
    final _ScanPlan plan = _plan;
    final String where = plan.hasSetting ? plan.setting : 'this space';
    final int count = plan.suggestions.length;
    if (plan.hasTidiness) {
      return 'Looking at the $where, I would call it ${_titleCase(plan.tidiness)}. '
          'Here are $count concrete actions, each one something you can do with '
          'your hands right now.';
    }
    return 'Looking at the $where, here is what stands out and the $count '
        'concrete actions for it.';
  }

  /// v0.6.9: the Next control is rate limited so rapid tapping cannot
  /// outrun the coach while the plan is still being revealed.
  void _revealNext() {
    final DateTime now = DateTime.now();
    if (now.difference(_lastNextAt) < const Duration(milliseconds: 700)) {
      return;
    }
    _lastNextAt = now;
    _setUiState(() {
      if (_revealed < _lines.length) _revealed++;
    });
    _scrollToBottom();
  }

  void _openResult() {
    _setUiState(() {
      _stage = _ScanStage.result;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_chatScroll.hasClients) return;
      _chatScroll.animateTo(
        _chatScroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _copyPlan() async {
    await Clipboard.setData(ClipboardData(text: _planDigest()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plan copied')),
    );
  }

  String _planDigest() {
    final _ScanPlan plan = _plan;
    final String notes = _notesController.text.trim();
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('Stuff Organiser - tidy plan');
    if (plan.hasSetting) buffer.writeln('Setting: ${plan.setting}');
    if (plan.hasTidiness) {
      buffer.writeln('Mess level: ${_titleCase(plan.tidiness)}');
    }
    if (notes.isNotEmpty) {
      buffer.writeln('Context notes: $notes');
    }
    buffer.writeln();
    if (plan.observations.isNotEmpty) {
      buffer.writeln('What the coach saw');
      for (final String observation in plan.observations) {
        buffer.writeln('- $observation');
      }
      buffer.writeln();
    }
    buffer.writeln('Step-by-step plan');
    int index = 1;
    for (final _Suggestion suggestion in plan.suggestions) {
      buffer.writeln('$index. ${suggestion.title}');
      if (suggestion.detail.isNotEmpty) {
        buffer.writeln('   ${suggestion.detail}');
      }
      for (final String step in suggestion.steps) {
        buffer.writeln('   - $step');
      }
      index++;
    }
    buffer.writeln();
    if (plan.habits.isNotEmpty) {
      buffer.writeln('Keep it tidy');
      for (final String habit in plan.habits) {
        buffer.writeln('- $habit');
      }
    }
    return buffer.toString();
  }
}

/// v0.8.5: recognition-intake flow members on the scan state. The coach
/// chat waits for the recognition lane's object list (interim route) and
/// drafts its plan from what was actually pasted in.
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
      text: 'Paste the recognized object list below and I will coach you '
          'from what is actually in the room.',
    ),
  ];
  _setUiState(() {
    _lines = lines;
    _revealed = lines.length;
    _stage = _ScanStage.chat;
  });
  _scrollToBottom();
}

/// Paste intake for the recognition lane list (interim route).
Future<void> _openRecognitionPaste() async {
  final TextEditingController controller = TextEditingController();
  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: const Text('Recognized object list'),
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
            maxLines: 8,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Paste the list from the recognition lane',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Coach from this'),
        ),
      ],
    ),
  );
  final String raw = controller.text;
  controller.dispose();
  if (ok != true) return;
  final List<_RecognizedObject> items = _parseRecognition(raw);
  if (!mounted) return;
  if (items.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No object labels found in that text')),
    );
    return;
  }
  _setUiState(() {
    _plan = _recognitionPlan(items, _notesController.text.trim())
        .withVenue(_scanVenue);
    _awaitingRecognition = false;
  });
  _buildChatLines();
}
}
