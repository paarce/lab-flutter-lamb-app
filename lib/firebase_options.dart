// Firebase configuration using secrets from config/secrets.dart
// This file CAN be safely committed to source control
// Actual credentials are in lib/config/secrets.dart (gitignored)

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

import 'config/secrets.dart';

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: Secrets.firebaseWebApiKey,
    appId: Secrets.firebaseWebAppId,
    messagingSenderId: Secrets.firebaseMessagingSenderId,
    projectId: Secrets.firebaseProjectId,
    authDomain: Secrets.firebaseAuthDomain,
    storageBucket: Secrets.firebaseStorageBucket,
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: Secrets.firebaseWebApiKey,
    appId: Secrets.firebaseAndroidAppId,
    messagingSenderId: Secrets.firebaseMessagingSenderId,
    projectId: Secrets.firebaseProjectId,
    authDomain: Secrets.firebaseAuthDomain,
    storageBucket: Secrets.firebaseStorageBucket,
  );
}
