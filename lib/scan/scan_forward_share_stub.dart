import 'dart:typed_data';

/// Non-web stub: the forward action only asks for the browser share
/// sheet under kIsWeb.
Future<bool> sharePhotosViaWebShare({
  required List<Uint8List> bytes,
  required List<String> mimes,
  required String subject,
  required String body,
}) async => false;
