part of 'scan_flow.dart';

extension _ScanAnalyze on _ScanFlowScreenState {
  Future<void> _confirmAndAnalyse() async {
    await _stopListening();
    await _analyze();
  }

  /// v0.7: interpretation stays the Cellulose lane. The plan comes from the
  /// offline coach with the picked venue folded in, and the thinking state
  /// on the result page covers the wait for the lane wiring. v0.8: the
  /// render loader covers this wait and holds at least ~1.5s so it never
  /// flashes.
  Future<void> _analyze() async {
    if (_photos.isEmpty) return;
    final int runId = ++_runId;
    final String notes = _notesController.text.trim();

    _setUiState(() {
      _analyzing = true;
      _error = null;
      _lines = <_ChatLine>[];
      _revealed = 0;
    });

    await Future<void>.delayed(const Duration(milliseconds: 1500));
    final _ScanPlan plan = _demoPlan(_photos, notes).withVenue(_scanVenue);

    if (!mounted || runId != _runId) return;
    _setUiState(() {
      _plan = plan;
      _analyzing = false;
    });
    _buildChatLines();
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
