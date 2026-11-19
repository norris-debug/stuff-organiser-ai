part of 'scan_flow.dart';

extension _ScanAfterPhoto on _ScanFlowScreenState {
  /// v0.6.9: the after-tidying picture is the keyless concept render.
  /// The Gemini image generation lane is gone.
  Future<void> _generateAfterPhoto(_ScanPlan plan, int runId) async {
    final _PhotoItem? first = _photos.isEmpty ? null : _photos.first;
    final String url = _pollinationsUrl(plan, first?.bytes);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted || runId != _runId) return;
    setState(() {
      _afterBytes = null;
      _afterUrl = url;
      _afterLoading = false;
    });
  }

  String _pollinationsUrl(_ScanPlan plan, Uint8List? bytes) {
    final int seed = _photoSeed(bytes ?? Uint8List(0));
    final String where = plan.hasSetting ? plan.setting : 'room';
    final String prompt =
        'photorealistic tidy version of a $where after organising, items '
        'grouped and stacked, papers in one neat stack, cups stacked by size, '
        'cables coiled in a box, labelled baskets on the shelves, floor and '
        'surfaces clear, soft daylight';
    return 'https://image.pollinations.ai/prompt/${Uri.encodeComponent(prompt)}'
        '?width=1024&height=768&nologo=true&seed=$seed&model=flux';
  }
}
