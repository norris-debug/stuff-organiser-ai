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
      // v0.8.16 (Meiosis TC-20): the notes echo is the coach speaking -
      // it renders as a coach bubble, not a user bubble.
      lines.add(
        _ChatLine(
          text: 'You told me: ${_clip(notes, 140)} - I folded that into the plan.',
        ),
      );
    }
    for (int i = 0; i < plan.observations.length; i++) {
      // v0.8.9: verify- and flagged-tier reads are the coach's
      // confirmation points - the user can answer them inline.
      // v0.8.17: the flag rides the plan's parallel list now; the fixed
      // opening-word match stays as a fallback for plans without it.
      final bool isConfirmation = i < plan.observationConfirmations.length
          ? plan.observationConfirmations[i]
          : plan.observations[i].startsWith('I think I can also see') ||
              plan.observations[i].startsWith('A few reads were too unsure');
      lines.add(_ChatLine(
          text: plan.observations[i], isConfirmation: isConfirmation));
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
        // v0.8.16 (Meiosis TC-20): interjections are the coach's own
        // asides - they render as coach bubbles, not user bubbles.
        // v0.8.17: the asides rotate from the no-repeat pool, so two
        // consecutive coach messages never reuse the same aside.
        lines.add(_ChatLine(
            text: _scanVocab.asides.next(kCoachInterjections)));
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
    // v0.8.28 (R7-F2 copy): the venue fallback carried its own article
    // inside the shared 'Looking at the $where' template, so an empty
    // venue read "Looking at the this space". The article moves into the
    // value: a named venue renders 'the Living room', an empty one
    // renders 'your space'.
    final String where =
        plan.hasSetting ? 'the ${plan.setting}' : 'your space';
    final int count = plan.suggestions.length;
    // v0.8.17: the intro opens with a rotating opener from the scan's
    // vocabulary bundle, so consecutive scans never start alike.
    final String opener = _scanVocab.openers.next(kCoachOpeners);
    if (plan.hasTidiness) {
      // v0.8.28 (QA R8-F5): 'tidy' always pairs with 2 actions (total
      // <= 2 -> wanted = 2), so the generic hands-on tail read as a
      // contradiction - the tidy case gets its own tail.
      return '$opener Looking at $where, I would call it '
          '${_titleCase(plan.tidiness)}. Here are $count concrete actions'
          '${plan.tidiness == 'tidy' ? ' to keep it that way' : ', each one something you can do with your hands right now'}.';
    }
    return '$opener Looking at $where, here is what I would tackle '
        'and the $count concrete actions for it.';
  }

  /// v0.6.9: the Next control is rate limited so rapid tapping cannot
  /// outrun the coach while the plan is still being revealed.
  /// v0.8.18: the timestamp reads package:clock's clock.now() instead of
  /// DateTime.now() - inside widget tests fake time advances clock.now()
  /// with the pumps, so a pump-driven reveal loop can clear the cooldown,
  /// while production behavior is unchanged (clock.now() is wall time
  /// outside the test zone).
  void _revealNext() {
    final DateTime now = clock.now();
    if (now.difference(_lastNextAt) < const Duration(milliseconds: 700)) {
      return;
    }
    _lastNextAt = now;
    _setUiState(() {
      if (_revealed < _lines.length) _revealed++;
    });
    _scrollToBottom();
    _maybeFinishChatReveal();
  }

  /// v0.8.14: the standalone "Show my tidy plan" button is gone per the
  /// steward directive. Finishing the coach's reveal now flows straight
  /// into the tidy plan page, so the tidying suggestion is always
  /// delivered in the chat first and a premature skip onto an empty plan
  /// is impossible. The short delay lets the last line land before the
  /// transition.
  void _maybeFinishChatReveal() {
    if (_revealed < _lines.length || _lines.isEmpty) return;
    Future<void>.delayed(const Duration(milliseconds: 900)).then((_) {
      if (!mounted || _stage != _ScanStage.chat) return;
      if (_revealed < _lines.length) return;
      _openResult();
    });
  }

  void _openResult() {
    _setUiState(() {
      _stage = _ScanStage.result;
    });
    // v0.8.16 (TC-23): the scan's leave-behinds run as the result page
    // opens, so closing the tab can no longer lose anything.
    unawaited(_completeScanSideEffects());
  }

  /// v0.8.16: everything a scan must leave behind runs once, as the
  /// result page opens (TC-23):
  /// - the tidy plan auto-saves into the Tidy Plan tab;
  /// - the scanned venue auto-adds to "Your spaces" (TC-24);
  /// - the confirmed and verify objects from the recognition lane land as
  ///   unpacked items inside that venue's page. Flagged reads (under 50%
  ///   confidence) stay out - they are the "too unsure to act on" tier
  ///   by design.
  /// v0.8.18 (R2-01): everything this method needs is snapshotted before
  /// the first await. _resetFlow() can run while the item adds are still
  /// in flight (the user tapping "Scan another room"), and it clears
  /// _plan, _recognized and the venue field - without the snapshot the
  /// follow-up save read cleared state and silently saved nothing.
  Future<void> _completeScanSideEffects() async {
    if (_scanSideEffectsDone) return;
    _scanSideEffectsDone = true;
    final _ScanPlan plan = _plan;
    final List<_RecognizedObject> recognized =
        List<_RecognizedObject>.of(_recognized);
    final String venue = _scanVenue;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final AppState state = widget.appState;
    if (venue.isNotEmpty) {
      final Space space =
          await state.addSpaceIfMissing(venue, emoji: _emojiForVenue(venue));
      for (final _RecognizedObject object in recognized) {
        if (object.tier == 2) continue;
        final ItemCategory category = _bucketOf(object.label) == 0
            ? ItemCategory.paper
            : ItemCategory.household;
        // Rescans of the same room never stack duplicate items.
        if (state.findDuplicate(object.label, space.id) != null) continue;
        await state.addItem(
          name: object.label,
          category: category,
          spaceId: space.id,
          paperAction: category == ItemCategory.paper ? PaperAction.sort : null,
        );
      }
    }
    final _SaveResult result =
        await _savePlanToTidyList(plan: plan, venue: venue);
    if (!mounted) return;
    if (result == _SaveResult.saved || result == _SaveResult.corrupt) {
      messenger.showSnackBar(SnackBar(content: Text(_saveMessage(result))));
    }
  }

  String _saveMessage(_SaveResult result) => switch (result) {
        _SaveResult.saved => 'Saved to the Tidy Plan tab',
        _SaveResult.empty => 'Nothing to save - new round started',
        _SaveResult.corrupt =>
          'Could not save - the stored plan data is unreadable. Nothing was changed.',
      };

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
