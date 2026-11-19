import 'package:firebase_auth/firebase_auth.dart';

/// The signed-in user. In demo mode this is a local anonymous user.
class AppUser {
  const AppUser({
    required this.uid,
    this.email,
    this.isAnonymous = false,
    this.isDemo = false,
  });

  final String uid;
  final String? email;
  final bool isAnonymous;
  final bool isDemo;

  String get displayLabel {
    if (isDemo) return email == null ? 'Demo organiser' : 'Demo organiser (local)';
    if (email != null && email!.isNotEmpty) return email!;
    return isAnonymous ? 'Guest' : 'Organiser';
  }
}

/// Firebase Auth wrapper. When [auth] is null the service runs in demo mode
/// and hands out a local anonymous user.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth;

  final FirebaseAuth? _auth;

  bool get isDemo => _auth == null;

  AppUser _demoUser(String? email) => AppUser(
        uid: 'demo-local-user',
        email: email,
        isAnonymous: email == null,
        isDemo: true,
      );

  Future<AppUser?> currentUser() async {
    if (isDemo) return _demoUser(null);
    final User? user = _auth!.currentUser;
    if (user == null) return null;
    return AppUser(uid: user.uid, email: user.email, isAnonymous: user.isAnonymous);
  }

  Future<AppUser> signIn({required String email, required String password}) async {
    if (isDemo) return _demoUser(email);
    final UserCredential credential = await _auth!.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final User? user = credential.user;
    return AppUser(uid: user?.uid ?? '', email: user?.email ?? email);
  }

  Future<AppUser> signUp({required String email, required String password}) async {
    if (isDemo) return _demoUser(email);
    final UserCredential credential = await _auth!.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final User? user = credential.user;
    return AppUser(uid: user?.uid ?? '', email: user?.email ?? email);
  }

  /// Anonymous local user: used for the light start (and for demo mode).
  Future<AppUser> signInAnonymously() async {
    if (isDemo) return _demoUser(null);
    final UserCredential credential = await _auth!.signInAnonymously();
    final User? user = credential.user;
    return AppUser(
      uid: user?.uid ?? '',
      email: user?.email,
      isAnonymous: true,
    );
  }

  Future<void> signOut() async {
    if (isDemo) return;
    await _auth!.signOut();
  }
}
