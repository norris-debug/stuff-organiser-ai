import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/auth_service.dart';
import 'services/data_service.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final firebaseReady = await _initFirebase();

  final appState = AppState(
    authService: AuthService(auth: firebaseReady ? FirebaseAuth.instance : null),
    dataService: DataService(db: firebaseReady ? FirebaseFirestore.instance : null),
    prefs: prefs,
  );
  await appState.bootstrap();

  runApp(StuffOrganiserApp(appState: appState));
}

/// Demo mode entry point: if Firebase cannot be initialised (no
/// google-services.json / GoogleService-Info.plist, bad options, offline) the
/// app keeps running on in-memory mock data.
Future<bool> _initFirebase() async {
  const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  const appId = String.fromEnvironment('FIREBASE_APP_ID');
  const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

  try {
    if (apiKey.isNotEmpty && appId.isNotEmpty && senderId.isNotEmpty && projectId.isNotEmpty) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: apiKey,
          appId: appId,
          messagingSenderId: senderId,
          projectId: projectId,
          authDomain: authDomain.isNotEmpty ? authDomain : '$projectId.firebaseapp.com',
          storageBucket: storageBucket.isNotEmpty ? storageBucket : '$projectId.appspot.com',
        ),
      );
      return true;
    }
    await Firebase.initializeApp();
    return true;
  } catch (error) {
    debugPrint('Firebase unavailable, running in demo mode: $error');
    return false;
  }
}

class StuffOrganiserApp extends StatelessWidget {
  const StuffOrganiserApp({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: Consumer<AppState>(
        builder: (context, state, _) {
          return MaterialApp(
            title: 'Stuff Organiser AI',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(state.themePack),
            home: state.onboardingComplete ? const HomeShell() : const OnboardingScreen(),
          );
        },
      ),
    );
  }
}
