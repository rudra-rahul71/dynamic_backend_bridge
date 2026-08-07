import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Abstract contract for local notification management across applications.
abstract class NotificationService {
  /// Initializes the service with optional default configurations.
  Future<void> initialize({
    String defaultChannelId = 'default_channel',
    String defaultChannelName = 'Default Notifications',
    String defaultChannelDescription = 'Default app notifications',
    String defaultAndroidIcon = 'app_icon',
  });

  /// Requests notification and alarm permissions from the operating system.
  Future<bool> requestPermissions();

  /// Schedules a notification to trigger after [duration].
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required Duration duration,
    String? channelId,
    String? channelName,
    String? channelDescription,
  });

  /// Shows an immediate notification.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? channelId,
    String? channelName,
    String? channelDescription,
  });

  /// Cancels a specific notification by [id].
  Future<void> cancelNotification(int id);

  /// Cancels all scheduled or active notifications.
  Future<void> cancelAllNotifications();
}

class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Completer<void>? _initCompleter;
  bool _isInitialized = false;

  String defaultChannelId = 'default_channel';
  String defaultChannelName = 'Default Notifications';
  String defaultChannelDescription = 'Default app notifications';
  String defaultAndroidIcon = 'app_icon';

  @override
  Future<void> initialize({
    String defaultChannelId = 'default_channel',
    String defaultChannelName = 'Default Notifications',
    String defaultChannelDescription = 'Default app notifications',
    String defaultAndroidIcon = 'app_icon',
  }) async {
    this.defaultChannelId = defaultChannelId;
    this.defaultChannelName = defaultChannelName;
    this.defaultChannelDescription = defaultChannelDescription;
    this.defaultAndroidIcon = defaultAndroidIcon;

    if (_isInitialized) return;
    if (_initCompleter != null) return _initCompleter!.future;

    _initCompleter = Completer<void>();

    try {
      tz.initializeTimeZones();
      if (!kIsWeb) {
        try {
          final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
          final location = tz.getLocation(timeZoneInfo.identifier);
          tz.setLocalLocation(location);
        } catch (e) {
          debugPrint(
            'LocalNotificationService timezone warning: $e. Falling back to UTC.',
          );
          tz.setLocalLocation(tz.UTC);
        }
      }

      final androidSettings = AndroidInitializationSettings(defaultAndroidIcon);

      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        defaultPresentAlert: true,
        defaultPresentSound: true,
        defaultPresentBadge: true,
        defaultPresentBanner: true,
        defaultPresentList: true,
      );

      final initializationSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification clicked: ${details.payload}');
        },
      );

      _isInitialized = true;
      await requestPermissions();
      _initCompleter?.complete();
    } catch (e, stack) {
      debugPrint('LocalNotificationService initialization failed: $e\n$stack');
      _initCompleter?.completeError(e, stack);
      _initCompleter = null;
    }
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      if (kIsWeb) return false;
      if (Platform.isIOS) {
        final iosImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        return await iosImplementation?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      } else if (Platform.isMacOS) {
        final macosImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >();
        return await macosImplementation?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      } else if (Platform.isAndroid) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        return await androidImplementation?.requestNotificationsPermission() ??
            false;
      }
    } catch (e) {
      debugPrint('LocalNotificationService requestPermissions error: $e');
    }
    return false;
  }

  NotificationDetails _getNotificationDetails({
    required String channelId,
    required String channelName,
    required String channelDescription,
  }) {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
      presentBanner: true,
      presentList: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
  }

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required Duration duration,
    String? channelId,
    String? channelName,
    String? channelDescription,
  }) async {
    if (kIsWeb) return;

    if (!_isInitialized) {
      await initialize();
    }

    if (duration.inSeconds <= 0) return;

    final scheduledDate = tz.TZDateTime.now(tz.local).add(duration);
    final details = _getNotificationDetails(
      channelId: channelId ?? defaultChannelId,
      channelName: channelName ?? defaultChannelName,
      channelDescription: channelDescription ?? defaultChannelDescription,
    );

    try {
      // Try exact alarm scheduling first
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on PlatformException catch (e) {
      debugPrint(
        'LocalNotificationService exact alarm failed ($e). Retrying with inexact schedule.',
      );
      // Safe fallback if exact alarm permission is denied on Android 12+
      try {
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (retryError) {
        debugPrint(
          'LocalNotificationService scheduleNotification fallback error: $retryError',
        );
      }
    } catch (e) {
      debugPrint('LocalNotificationService scheduleNotification error: $e');
    }
  }

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? channelId,
    String? channelName,
    String? channelDescription,
  }) async {
    if (kIsWeb) return;

    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _getNotificationDetails(
          channelId: channelId ?? defaultChannelId,
          channelName: channelName ?? defaultChannelName,
          channelDescription: channelDescription ?? defaultChannelDescription,
        ),
      );
    } catch (e) {
      debugPrint('LocalNotificationService showNotification error: $e');
    }
  }

  @override
  Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;

    try {
      await _notificationsPlugin.cancel(id: id);
    } catch (e) {
      debugPrint('LocalNotificationService cancelNotification error: $e');
    }
  }

  @override
  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;

    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('LocalNotificationService cancelAllNotifications error: $e');
    }
  }
}
