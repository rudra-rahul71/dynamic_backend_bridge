import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'app_banner_service.dart';

abstract class RemoteNotificationService {
  Future<void> initialize();
  Future<String?> getToken();
  Future<void> deleteToken();
  Stream<String> get onTokenRefresh;
}

class FCMNotificationService implements RemoteNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  bool _isInitialized = false;

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

      // Trigger top in-app banner directly on foreground push notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        final title =
            message.notification?.title ??
            message.data['title'] ??
            'Notification';
        final body = message.notification?.body ?? message.data['body'];

        AppBannerService.showInfo(
          null,
          title: title,
          body: body,
          data: message.data,
        );
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
            'APNS token is not set yet (likely on Simulator). Skipping FCM token fetch.',
          );
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
