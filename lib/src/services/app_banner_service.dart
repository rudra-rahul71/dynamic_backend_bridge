import 'dart:async';
import 'package:flutter/material.dart';
import '../ui/app_banner.dart';

/// Overlay manager service to display floating in-app notification banners.
abstract class AppBannerService {
  /// Global navigator key that apps can set on MaterialApp/GoRouter for context-less banner display.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static OverlayEntry? _currentOverlayEntry;
  static Timer? _dismissTimer;

  /// Programmatically hides the currently visible banner.
  static void hideCurrentBanner() {
    _dismissTimer?.cancel();
    _dismissTimer = null;

    if (_currentOverlayEntry != null) {
      if (_currentOverlayEntry!.mounted) {
        _currentOverlayEntry!.remove();
      }
      _currentOverlayEntry = null;
    }
  }

  /// Displays a success banner message.
  static void showSuccess(
    BuildContext? context,
    String message, {
    String? title,
    Duration? duration,
  }) {
    _showBanner(
      context: context,
      type: AppBannerType.success,
      title: title ?? 'Success',
      body: message,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  /// Displays an error banner message.
  static void showError(
    BuildContext? context,
    String message, {
    String? title,
    Duration? duration,
  }) {
    _showBanner(
      context: context,
      type: AppBannerType.error,
      title: title ?? 'Error',
      body: message,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  /// Displays an informational banner message with optional custom data and tap action.
  static void showInfo(
    BuildContext? context, {
    required String title,
    String? body,
    Map<String, dynamic>? data,
    VoidCallback? onTap,
    Duration? duration,
  }) {
    _showBanner(
      context: context,
      type: AppBannerType.info,
      title: title,
      body: body,
      onTap: () {
        hideCurrentBanner();
        onTap?.call();
      },
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  static void _showBanner({
    BuildContext? context,
    required AppBannerType type,
    required String title,
    String? body,
    VoidCallback? onTap,
    Duration? duration,
  }) {
    // Immediately remove existing overlay if present before showing a new banner
    hideCurrentBanner();

    final targetContext = context ?? navigatorKey.currentContext;
    OverlayState? overlayState;
    if (targetContext != null) {
      overlayState =
          Overlay.maybeOf(targetContext, rootOverlay: true) ??
          Overlay.maybeOf(targetContext);
    }
    overlayState ??= navigatorKey.currentState?.overlay;

    if (overlayState == null) {
      debugPrint(
        'AppBannerService warning: Could not locate OverlayState to display banner.',
      );
      return;
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: AppBannerWidget(
              type: type,
              title: title,
              body: body,
              onTap: onTap,
              onDismissed: () {
                if (_currentOverlayEntry == entry) {
                  if (entry.mounted) {
                    entry.remove();
                  }
                  _currentOverlayEntry = null;
                }
              },
            ),
          ),
        );
      },
    );

    _currentOverlayEntry = entry;
    overlayState.insert(entry);

    if (duration != null && duration > Duration.zero) {
      _dismissTimer = Timer(duration, () {
        hideCurrentBanner();
      });
    }
  }
}
