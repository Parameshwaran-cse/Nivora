import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase initialization service
/// 
/// SETUP INSTRUCTIONS (do once in Firebase Console):
/// 
/// 1. Go to https://console.firebase.google.com
/// 2. Create a new project (or use existing) named "nivora"
/// 3. Enable the following services:
///    - Authentication > Sign-in method > Email/Password (for admin)
///    - Firestore Database > Create database (start in test mode, we'll lock down with rules later)
///    - Storage > Get started (default bucket)
///    - App Check (optional but recommended) > Register app with reCAPTCHA v3 / DeviceCheck / App Attest
/// 
/// 4. Add an Android app:
///    - Package name: com.nivora.app (or your chosen package name)
///    - Download google-services.json → place in android/app/
/// 
/// 5. Add an iOS app:
///    - Bundle ID: com.nivora.app (or your chosen bundle ID)
///    - Download GoogleService-Info.plist → place in ios/Runner/
/// 
/// 6. For Web (if needed):
///    - Add web app, copy firebaseConfig values
/// 
/// 7. After adding apps, update this file with your actual Firebase options
///    (replace the placeholder values below with your project's config)
/// 
/// 8. Firestore Security Rules (deploy via Firebase CLI):
///    - See SECURITY_RULES.md for the rules matching SRD Section 8
/// 
/// 9. Storage Rules (deploy via Firebase CLI):
///    - See STORAGE_RULES.md for the rules matching SRD Section 8.4
/// 
/// 10. Set admin custom claim for your account:
///     firebase auth:set-custom-user-claims `<your-uid>` '{"role": "admin"}'

import '../firebase_options.dart';

class FirebaseService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    _initialized = true;

    if (kDebugMode) {
      print('Firebase initialized successfully');
    }
  }

  static bool get isInitialized => _initialized;
}