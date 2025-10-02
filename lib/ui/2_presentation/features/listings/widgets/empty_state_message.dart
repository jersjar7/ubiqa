// lib/ui/2_presentation/features/listings/widgets/empty_state_message.dart

import 'dart:async';
import 'package:flutter/cupertino.dart';

// Import theme
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';

/// Empty State Message Widget
///
/// Displays a dismissible notification when no listings are available.
/// Auto-dismisses after 5 seconds OR can be manually dismissed via X button.
///
/// Usage:
/// ```dart
/// EmptyStateMessage(
///   message: 'Pronto, más propiedades disponibles',
///   onDismissed: () {
///     // Optional: Handle dismissal in parent
///   },
/// )
/// ```
class EmptyStateMessage extends StatefulWidget {
  final String message;
  final VoidCallback? onDismissed;
  final Duration autoDismissDuration;

  const EmptyStateMessage({
    super.key,
    required this.message,
    this.onDismissed,
    this.autoDismissDuration = const Duration(seconds: 5),
  });

  @override
  State<EmptyStateMessage> createState() => _EmptyStateMessageState();
}

class _EmptyStateMessageState extends State<EmptyStateMessage> {
  Timer? _autoDismissTimer;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _startAutoDismissTimer();
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  void _startAutoDismissTimer() {
    _autoDismissTimer = Timer(widget.autoDismissDuration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    setState(() => _isVisible = false);

    // Notify parent after fade-out animation completes
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        widget.onDismissed?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: IgnorePointer(
        ignoring: !_isVisible,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            child: Stack(
              children: [
                // Message container
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.callout.copyWith(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                // Dismiss button (top-right corner)
                Positioned(
                  top: 0,
                  right: 0,
                  child: CupertinoButton(
                    padding: const EdgeInsets.all(12),
                    onPressed: _dismiss,
                    minimumSize: Size(0, 0),
                    child: Icon(
                      CupertinoIcons.xmark_circle_fill,
                      size: 20,
                      color: CupertinoColors.white.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
