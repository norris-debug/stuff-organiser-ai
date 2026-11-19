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
    buffer.writeln();
    buffer.writeln(
      'After-shot: AI concept sketch built from the setting text.',
    );
    return buffer.toString();
  }

  void _resetFlow() {
    _runId++;
    unawaited(_stopListening());
    _setUiState(() {
      _photos = <_PhotoItem>[];
      _notesController.clear();
      _listening = false;
      _lines = <_ChatLine>[];
      _revealed = 0;
      _stage = _ScanStage.pick;
      _plan = const _ScanPlan(
        observations: <String>[],
        habits: <String>[],
      );
      _afterBytes = null;
      _afterUrl = null;
      _afterLoading = false;
      _error = null;
      _analyzing = false;
    });
  }
}
