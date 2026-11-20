import '../models/space.dart';
import 'app_state.dart';

/// v0.8.16: scan-driven space helpers on AppState.
extension AppStateSpaces on AppState {
  /// The space whose name matches [name] case-insensitively, or `null`.
  Space? spaceByName(String name) {
    final String target = name.trim().toLowerCase();
    if (target.isEmpty) return null;
    for (final Space space in spaces) {
      if (space.name.trim().toLowerCase() == target) return space;
    }
    return null;
  }

  /// Returns the space named [name], creating it first when missing.
  ///
  /// Every scan with a venue auto-adds that venue to "Your spaces"
  /// (Meiosis TC-24 / Herrick's redesign). Rescanning the same room
  /// reuses the existing space instead of stacking duplicates.
  Future<Space> addSpaceIfMissing(String name, {String emoji = '📦'}) async {
    final Space? existing = spaceByName(name);
    if (existing != null) return existing;
    return addSpace(name, emoji: emoji);
  }
}