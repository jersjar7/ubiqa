// lib/ui/2_presentation/features/listings/widgets/new_listing.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Import theme
import '../../../shared/theme/app_colors.dart';

// Import pages
import '../pages/new_listing_form.dart';

/// New Listing Button Widget
///
/// Floating action button that opens the new listing form.
/// Positioned bottom-right of map view.
/// White circle with plus icon for clear call-to-action.
class NewListingButton extends StatelessWidget {
  const NewListingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToNewListingForm(context),
      child: Container(
        width: 56.0,
        height: 56.0,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 12.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          CupertinoIcons.add,
          color: AppColors.primary,
          size: 28.0,
        ),
      ),
    );
  }

  void _navigateToNewListingForm(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => const NewListingFormPage(),
      ),
    );
  }
}