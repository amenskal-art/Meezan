// Firebase configuration via --dart-define (no google-services.json needed:
// FlutterFire supports pure-Dart initialization).
// CI injects these from GitHub Secrets; see README "3. GitHub Secrets".
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static const String _projectId =
      String.fromEnvironment('FB_PROJECT_ID', defaultValue: 'REPLACE_ME');
  static const String _senderId =
      String.fromEnvironment('FB_SENDER_ID', defaultValue: 'REPLACE_ME');
  static const String _bucket =
      String.fromEnvironment('FB_STORAGE_BUCKET', defaultValue: 'REPLACE_ME');

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment('FB_ANDROID_API_KEY', defaultValue: 'REPLACE_ME'),
    appId: String.fromEnvironment('FB_ANDROID_APP_ID', defaultValue: 'REPLACE_ME'),
    messagingSenderId: _senderId,
    projectId: _projectId,
    storageBucket: _bucket,
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment('FB_WEB_API_KEY', defaultValue: 'REPLACE_ME'),
    appId: String.fromEnvironment('FB_WEB_APP_ID', defaultValue: 'REPLACE_ME'),
    messagingSenderId: _senderId,
    projectId: _projectId,
    storageBucket: _bucket,
    authDomain: String.fromEnvironment('FB_AUTH_DOMAIN', defaultValue: 'REPLACE_ME'),
  );

  static FirebaseOptions get currentPlatform => kIsWeb ? web : android;

  /// True when the build was produced without real Firebase secrets.
  static bool get isConfigured => currentPlatform.apiKey != 'REPLACE_ME';
}
