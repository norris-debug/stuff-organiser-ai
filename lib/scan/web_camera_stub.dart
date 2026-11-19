import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Non-web placeholder. Never called: scan_flow only routes to this facade
/// when kIsWeb is true, and other platforms use the native camera picker.
Future<XFile?> captureWithWebCamera(
  BuildContext context, {
  VoidCallback? onFallback,
}) async {
  return null;
}
