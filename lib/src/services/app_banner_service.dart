import 'dart:async';
import 'package:flutter/material.dart';
import '../ui/app_banner.dart';

/// Overlay manager service to display floating in-app notification banners.
class AppBannerService {
  static final AppBannerService _instance = AppBannerService._internal();

  factory AppBannerService() => _instance;

  AppBannerService._internal();

  static AppBannerService get instance => _instance;

  OverlayEntry? _currentOverlayEntry;
  Timer? _dismissTimer;
  GlobalKey<AppBannerWidgetState>? _currentKey;

  /// Programmatically hides the currently visible banner with a slide-up exit animation.
  void hideCurrentBanner() {
    _dismissTimer?.cancel();
    _dismissTimer = null;

    if (_currentKey?.currentState != null) {
      final state = _currentKey!.currentState;
      _currentKey = null;
      state?.dismiss();
    } else if (_currentOverlayEntry != null) {
      if (_currentOverlayEntry!.mounted) {
        _currentOverlayEntry!.remove();
      }
      _currentOverlayEntry = null;
    }
  }

  /// Displays a success banner message.
  void showSuccess(
    BuildContext context,
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
  void showError(
    BuildContext context,
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
  void showInfo(
    BuildContext context, {
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

  void _showBanner({
    required BuildContext context,
    required AppBannerType type,
    required String title,
    String? body,
    VoidCallback? onTap,
    Duration? duration,
  }) {
    // Immediately remove existing overlay if present before showing a new banner
    _removeOverlayImmediately();

    final overlayState =
        Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.of(context);

    final key = GlobalKey<AppBannerWidgetState>();
    _currentKey = key;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: AppBannerWidget(
              key: key,
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
                  _currentKey = null;
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

  void _removeOverlayImmediately() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (_currentOverlayEntry != null) {
      if (_currentOverlayEntry!.mounted) {
        _currentOverlayEntry!.remove();
      }
      _currentOverlayEntry = null;
    }
    _currentKey = null;
  }
}
