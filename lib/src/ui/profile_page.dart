import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../auth/auth_repository.dart';
import '../services/app_banner_service.dart';

class DynamicProfilePage extends StatefulWidget {
  final String header;
  final String sub;
  final String? userEmail;
  final Future<void> Function()? onSignOut;
  final VoidCallback? onSignOutSuccess;

  const DynamicProfilePage({
    super.key,
    this.header = 'Account Settings',
    this.sub = 'Manage profile details, sessions, and log out',
    this.userEmail,
    this.onSignOut,
    this.onSignOutSuccess,
  });

  @override
  State<DynamicProfilePage> createState() => _DynamicProfilePageState();
}

class _DynamicProfilePageState extends State<DynamicProfilePage> {
  UserEntity? _currentUser;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    if (GetIt.instance.isRegistered<AuthRepository>()) {
      _currentUser = GetIt.instance<AuthRepository>().currentUser;
    }
  }

  Future<void> _handleSignOut() async {
    setState(() {
      _isSigningOut = true;
    });

    try {
      if (widget.onSignOut != null) {
        await widget.onSignOut!();
      } else if (GetIt.instance.isRegistered<AuthRepository>()) {
        final authRepo = GetIt.instance<AuthRepository>();
        await authRepo.signOut();
      }

      if (mounted && widget.onSignOutSuccess != null) {
        widget.onSignOutSuccess!();
      }
    } catch (e) {
      if (mounted) {
        AppBannerService.showError(
          context,
          'Sign out error: ${e.toString()}',
          title: 'Error',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final displayEmail =
        widget.userEmail ?? _currentUser?.email ?? 'Unknown User';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Page Header matching original design
            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.header,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.sub,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // User Avatar & Email Card matching original design
            Card(
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: primaryColor.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.person_rounded,
                        size: 48,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayEmail,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Sign Out Button matching original design
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.errorContainer.withValues(
                  alpha: 0.2,
                ),
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(
                  color: theme.colorScheme.error.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isSigningOut ? null : _handleSignOut,
              icon: _isSigningOut
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.error,
                        ),
                      ),
                    )
                  : const Icon(Icons.logout_rounded),
              label: Text(
                _isSigningOut ? 'LOGGING OUT...' : 'SIGN OUT',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
