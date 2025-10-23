// lib/ui/2_presentation/shared/widgets/profile_button.dart

import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';

/// Glowing Presence Profile Button
///
/// Elevated profile button with:
/// - Soft pulsing glow ring indicating online/active status
/// - Subtle depth with layered shadows
/// - Gentle scale feedback on press
/// - Modern glass-like border
///
/// Memorable but production-ready.
class ProfileButton extends StatefulWidget {
  final String? profileImageUrl;
  final VoidCallback onTap;
  final double size;

  const ProfileButton({
    super.key,
    this.profileImageUrl,
    required this.onTap,
    this.size = 44.0,
  });

  @override
  State<ProfileButton> createState() => _ProfileButtonState();
}

class _ProfileButtonState extends State<ProfileButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    // Gentle breathing glow - subtle presence indicator
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.1,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Outer glow ring - pulsing presence
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(
                      alpha: _glowAnimation.value * 0.4,
                    ),
                    blurRadius: 16.0,
                    spreadRadius: 2.0,
                  ),
                  BoxShadow(
                    color: AppColors.accent.withValues(
                      alpha: _glowAnimation.value * 0.2,
                    ),
                    blurRadius: 24.0,
                    spreadRadius: 4.0,
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.background,
                  // Glass-like border with gradient
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 2.5,
                  ),
                  // Elevated depth shadows
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.08),
                      blurRadius: 8.0,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.04),
                      blurRadius: 16.0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Profile image or default icon
                      if (widget.profileImageUrl != null &&
                          widget.profileImageUrl!.isNotEmpty)
                        Image.network(
                          widget.profileImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultIcon();
                          },
                        )
                      else
                        _buildDefaultIcon(),

                      // Subtle inner highlight for glass effect
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: widget.size * 0.4,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.background.withValues(alpha: 0.2),
                                AppColors.background.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDefaultIcon() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.accent.withValues(alpha: 0.15),
          ],
        ),
      ),
      child: Icon(
        CupertinoIcons.person_fill,
        color: AppColors.primary,
        size: widget.size * 0.5,
      ),
    );
  }
}
