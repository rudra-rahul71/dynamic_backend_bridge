import 'package:flutter/material.dart';

enum AppBannerType { success, error, info }

/// Top floating banner card widget styled with theme surface background, elevation,
/// rounded corners, and type accent indicator.
///
/// Supports slide-down entry animation, slide-up exit animation, swipe-up gesture to dismiss,
/// title, body message, optional action button, and close button.
class AppBannerWidget extends StatefulWidget {
  final AppBannerType type;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final VoidCallback? onTap;
  final VoidCallback? onClose;
  final VoidCallback? onDismissed;
  final Duration animationDuration;

  const AppBannerWidget({
    super.key,
    required this.type,
    required this.title,
    this.body,
    this.actionLabel,
    this.onActionTap,
    this.onTap,
    this.onClose,
    this.onDismissed,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<AppBannerWidget> createState() => AppBannerWidgetState();
}

class AppBannerWidgetState extends State<AppBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Triggers reverse slide-up animation and notifies callback when finished.
  Future<void> dismiss() async {
    if (_isDismissing || !mounted) return;
    _isDismissing = true;
    try {
      await _controller.reverse();
    } catch (_) {}
    if (mounted) {
      widget.onDismissed?.call();
    }
  }

  Color _getAccentColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (widget.type) {
      case AppBannerType.success:
        return Colors.green.shade600;
      case AppBannerType.error:
        return theme.colorScheme.error;
      case AppBannerType.info:
        return theme.colorScheme.primary;
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case AppBannerType.success:
        return Icons.check_circle_rounded;
      case AppBannerType.error:
        return Icons.error_rounded;
      case AppBannerType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = _getAccentColor(context);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.primaryDelta != null && details.primaryDelta! < -4) {
              dismiss();
            }
          },
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null && details.primaryVelocity! < -100) {
              dismiss();
            }
          },
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: accentColor.withOpacity(0.45),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12.0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type accent icon
                    Container(
                      padding: const EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIcon(),
                        color: accentColor,
                        size: 20.0,
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    // Title & Body
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          if (widget.body != null &&
                              widget.body!.isNotEmpty) ...[
                            const SizedBox(height: 4.0),
                            Text(
                              widget.body!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.8),
                              ),
                            ),
                          ],
                          if (widget.actionLabel != null &&
                              widget.actionLabel!.isNotEmpty) ...[
                            const SizedBox(height: 6.0),
                            GestureDetector(
                              onTap: widget.onActionTap,
                              child: Text(
                                widget.actionLabel!,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: accentColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    // Close button
                    GestureDetector(
                      onTap: () {
                        widget.onClose?.call();
                        dismiss();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18.0,
                          color: theme.colorScheme.onSurface
                              .withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
