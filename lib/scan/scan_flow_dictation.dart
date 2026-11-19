part of 'scan_flow.dart';

extension _ScanDictation on _ScanFlowScreenState {
  Future<void> _toggleDictation() async {
    if (_listening) {
      setState(() {
        _listening = false;
      });
      await _stopListening();
      return;
    }
    if (!kIsWeb) {
      final permissions.PermissionStatus status =
          await permissions.Permission.microphone.request();
      if (!status.isGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is needed for dictation.'),
          ),
        );
        return;
      }
    }
    final speech.SpeechToText engine = _speech ??= speech.SpeechToText();
    if (!_speechAvailable) {
      try {
        _speechAvailable = await engine.initialize(
          onError: (Object error) {},
          onStatus: _onSpeechStatus,
        );
      } catch (_) {
        _speechAvailable = false;
      }
      if (!_speechAvailable) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Voice is not available here. Typing is the way on this device.',
            ),
          ),
        );
        return;
      }
    }
    _dictationBase = _notesController.text.trim();
    try {
      await engine.listen(
        onResult: (result) => _onSpeechResult(result.recognizedWords),
        listenOptions: speech.SpeechListenOptions(
          cancelOnError: true,
          partialResults: true,
          listenMode: speech.ListenMode.dictation,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start the microphone. Please type instead.'),
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _listening = true;
    });
  }

  Future<void> _stopListening() async {
    final speech.SpeechToText? engine = _speech;
    if (engine == null) return;
    try {
      await engine.stop();
    } catch (_) {
      // Best effort stop; the status listener also clears the flag.
    }
  }

  void _onSpeechStatus(String status) {
    if (!mounted) return;
    if (status == speech.SpeechToText.notListeningStatus && _listening) {
      setState(() {
        _listening = false;
      });
    }
  }

  void _onSpeechResult(String recognizedWords) {
    final String recognized = recognizedWords.trim();
    if (recognized.isEmpty) return;
    if (!mounted) return;
    setState(() {
      _notesController.text = _dictationBase.isEmpty
          ? recognized
          : '$_dictationBase $recognized';
      _notesController.selection = TextSelection.collapsed(
        offset: _notesController.text.length,
      );
    });
  }
}
