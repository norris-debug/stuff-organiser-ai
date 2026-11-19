part of 'scan_flow.dart';

extension _ScanAnalyze on _ScanFlowScreenState {
  Future<void> _confirmAndAnalyse() async {
    await _stopListening();
    await _analyze();
  }

  /// v0.6.9: interpretation is the Cellulose lane. The in-app Gemini call is
  /// gone, so the plan comes from the offline coach while the thinking state
  /// covers the wait for the lane wiring.
  Future<void> _analyze() async {
    if (_photos.isEmpty) return;
    final int runId = ++_runId;
    final String notes = _notesController.text.trim();

    setState(() {
      _analyzing = true;
      _error = null;
      _lines = <_ChatLine>[];
      _revealed = 0;
      _afterBytes = null;
      _afterUrl = null;
      _afterLoading = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 1200));
    final _ScanPlan plan = _demoPlan(_photos, notes);

    if (!mounted || runId != _runId) return;
    setState(() {
      _plan = plan;
      _analyzing = false;
    });
    _buildChatLines();
    unawaited(_generateAfterPhoto(plan, runId));
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
