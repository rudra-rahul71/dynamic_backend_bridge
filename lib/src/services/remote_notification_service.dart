import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

abstract class RemoteNotificationService {
  Future<void> initialize();
  Future<String?> getToken();
  Future<void> deleteToken();
  Stream<String> get onTokenRefresh;
  Stream<RemoteMessage> get onForegroundMessage;
}

class FCMNotificationService implements RemoteNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final StreamController<RemoteMessage> _foregroundMessageController =
      StreamController<RemoteMessage>.broadcast();
  bool _isInitialized = false;

  @override
  Stream<RemoteMessage> get onForegroundMessage =>
      _foregroundMessageController.stream;

  @override
  Future<void> initialize() async {
    if (_isInitialized || kIsWeb) return;

    try {
      // Request permissions (Required for iOS, and Android 13+)
      await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint(
              'Message also contained a notification: ${message.notification}');
        }

        _foregroundMessageController.add(message);
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('FCMNotificationService initialization failed: $e');
    }
  }

  @override
  Future<String?> getToken() async {
    if (kIsWeb) return null;
    try {
      if (Platform.isIOS) {
        // Wait up to 3 seconds for APNS token to be available (often delayed on simulators)
        String? apnsToken;
        for (int i = 0; i < 3; i++) {
          apnsToken = await _firebaseMessaging.getAPNSToken();
          if (apnsToken != null) break;
          await Future.delayed(const Duration(seconds: 1));
        }

        if (apnsToken == null) {
          debugPrint(
              'APNS token is not set yet (likely on Simulator). Skipping FCM token fetch.');
          return null;
        }
      }
      return await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint('FCMNotificationService getToken error: $e');
      return null;
    }
  }

  @override
  Future<void> deleteToken() async {
    if (kIsWeb) return;
    try {
      await _firebaseMessaging.deleteToken();
    } catch (e) {
      debugPrint('FCMNotificationService deleteToken error: $e');
    }
  }

  @override
  Stream<String> get onTokenRefresh => _firebaseMessaging.onTokenRefresh;
}
