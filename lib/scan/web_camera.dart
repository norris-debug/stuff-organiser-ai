/// Web camera capture facade.
///
/// On the web build this resolves to the getUserMedia based in-app camera
/// (web_camera_web.dart). On every other platform the stub is used and the
/// native camera picker in scan_flow handles capture instead.
export 'web_camera_stub.dart' if (dart.library.html) 'web_camera_web.dart';
