// lib/ui/2_presentation/shared/widgets/profile_drawer.dart

import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Profile Drawer Widget
///
/// Left-sliding drawer displaying user profile and navigation options.
/// Scalable design allows adding new menu items as app grows.
///
/// Features:
/// - Slides from left edge horizontally (true drawer behavior)
/// - Rounded corners on right side
/// - Organized sections (Account, Properties, Settings)
/// - Each item can navigate to dedicated pages
class ProfileDrawer extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String? profileImageUrl;
  final VoidCallback onSignOut;

  const ProfileDrawer({
    super.key,
    required this.userName,
    required this.userEmail,
    this.profileImageUrl,
    required this.onSignOut,
  });

  /// Show profile drawer with proper left-to-right animation
  static void show({
    required BuildContext context,
    required String userName,
    required String userEmail,
    String? profileImageUrl,
    required VoidCallback onSignOut,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false, // Allows background to show through
        barrierColor: CupertinoColors.black.withValues(alpha: 0.5),
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return ProfileDrawer(
            userName: userName,
            userEmail: userEmail,
            profileImageUrl: profileImageUrl,
            onSignOut: onSignOut,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide from left animation
          const begin = Offset(-1.0, 0.0); // Start off-screen to the left
          const end = Offset.zero; // End at normal position
          const curve = Curves.easeOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () {}, // Prevent dismissal when tapping drawer
          child: SafeArea(
            child: Container(
              width: 300,
              height: double.infinity,
              decoration: BoxDecoration(
                // Solid black background
                color: AppColors.textPrimary.withValues(alpha: 0.95),
                // Rounded corners on RIGHT side only
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(10, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header section
                  _buildHeader(context),

                  // Scrollable menu items
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          // Account Section
                          _buildSectionHeader('CUENTA'),
                          _buildMenuItem(
                            context: context,
                            icon: CupertinoIcons.person_circle,
                            title: 'Mi Perfil',
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).pushNamed('/profile');
                            },
                          ),

                          // Properties Section (Future)
                          _buildSectionHeader('PROPIEDADES'),
                          _buildMenuItem(
                            context: context,
                            icon: CupertinoIcons.building_2_fill,
                            title: 'Mis Propiedades',
                            onTap: () {
                              Navigator.of(context).pop();
                              // TODO: Navigate to my listings
                              _showComingSoon(context, 'Mis Propiedades');
                            },
                          ),
                          _buildMenuItem(
                            context: context,
                            icon: CupertinoIcons.heart_fill,
                            title: 'Favoritos',
                            onTap: () {
                              Navigator.of(context).pop();
                              // TODO: Navigate to favorites
                              _showComingSoon(context, 'Favoritos');
                            },
                          ),

                          // Settings Section (Future)
                          _buildSectionHeader('CONFIGURACIÓN'),
                          _buildMenuItem(
                            context: context,
                            icon: CupertinoIcons.settings,
                            title: 'Configuración',
                            onTap: () {
                              Navigator.of(context).pop();
                              // TODO: Navigate to settings
                              _showComingSoon(context, 'Configuración');
                            },
                          ),
                          _buildMenuItem(
                            context: context,
                            icon: CupertinoIcons.bell_fill,
                            title: 'Notificaciones',
                            onTap: () {
                              Navigator.of(context).pop();
                              // TODO: Navigate to notifications
                              _showComingSoon(context, 'Notificaciones');
                            },
                          ),

                          // Help Section
                          _buildSectionHeader('SOPORTE'),
                          _buildMenuItem(
                            context: context,
                            icon: CupertinoIcons.question_circle_fill,
                            title: 'Ayuda',
                            onTap: () {
                              Navigator.of(context).pop();
                              // TODO: Navigate to help
                              _showComingSoon(context, 'Ayuda');
                            },
                          ),

                          const SizedBox(height: 16),

                          // Sign Out (always visible at bottom of scroll)
                          _buildSignOutButton(context),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build drawer header with user info
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
      decoration: BoxDecoration(
        // Solid black - NO gradient background
        color: AppColors.textPrimary.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.white.withValues(alpha: 015),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Avatar with glow - gradient ONLY in circle
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.accent],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: profileImageUrl != null && profileImageUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      profileImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          CupertinoIcons.person_fill,
                          size: 32,
                          color: CupertinoColors.white,
                        );
                      },
                    ),
                  )
                : Icon(
                    CupertinoIcons.person_fill,
                    size: 32,
                    color: CupertinoColors.white,
                  ),
          ),
          const SizedBox(height: 14),

          // User Name
          Text(
            userName,
            style: AppTextStyles.title2.copyWith(
              color: CupertinoColors.white,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),

          // User Email
          Text(
            userEmail,
            style: AppTextStyles.caption1.copyWith(
              color: CupertinoColors.white.withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Row(
        children: [
          Text(
            title,
            style: AppTextStyles.caption2.copyWith(
              color: CupertinoColors.white.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Build menu item
  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Icon with background
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppColors.primary.withValues(alpha: 0.9),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),

            // Title
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.callout.copyWith(
                  color: CupertinoColors.white.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Chevron
            Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.white.withValues(alpha: 0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// Build sign out button
  Widget _buildSignOutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        color: AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        onPressed: () {
          Navigator.of(context).pop();
          _showSignOutConfirmation(context);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.square_arrow_right,
              color: AppColors.error.withValues(alpha: 0.9),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Cerrar Sesión',
              style: AppTextStyles.callout.copyWith(
                color: AppColors.error.withValues(alpha: 0.95),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show sign out confirmation dialog
  void _showSignOutConfirmation(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onSignOut();
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  /// Show coming soon dialog
  void _showComingSoon(BuildContext context, String feature) {
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(feature),
        content: const Text('Esta función estará disponible pronto.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
