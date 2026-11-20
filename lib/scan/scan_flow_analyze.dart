part of 'scan_flow.dart';

extension _ScanAnalyze on _ScanFlowScreenState {
  Future<void> _confirmAndAnalyse() async {
    await _stopListening();
    await _analyze();
  }

  /// v0.7: interpretation stays on the Cellulose lane. v0.8.5: the plan
  /// is no longer drafted from the canned demo script - the chat opens
  /// in a waiting state and the coach drafts from the recognized object
  /// list once it is pasted in (interim route, like the render slots).
  /// The render loader still covers the wait and holds at least ~1.5s
  /// so it never flashes.
  Future<void> _analyze() async {
    if (_photos.isEmpty) return;
    final int runId = ++_runId;

    // v0.8.17: seed the scan's vocabulary bundle so every conversation
    // rotates its own wording (no-repeat within each pool).
    _scanVocab = _CoachVocab(
        DateTime.now().microsecondsSinceEpoch & 0x7fffffff);

    _setUiState(() {
      _analyzing = true;
      _awaitingRecognition = true;
      _error = null;
      _lines = <_ChatLine>[];
      _revealed = 0;
      _angleRenders.clear();
    });

    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted || runId != _runId) return;
    _setUiState(() {
      _analyzing = false;
    });
    _buildAwaitingChat();
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
