// lib/ui/2_presentation/features/auth/widgets/country_selector_widget.dart

import 'package:flutter/cupertino.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../../../models/1_domain/shared/value_objects/international_phone_number.dart';

/// Compact Country Selector for Prefix Use
class CompactCountrySelector extends StatelessWidget {
  final SupportedCountryCode selectedCountry;
  final VoidCallback? onTap;
  final bool enabled;

  const CompactCountrySelector({
    super.key,
    required this.selectedCountry,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        constraints: const BoxConstraints(minWidth: 60.0),
        padding: const EdgeInsets.only(right: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getCountryFlag(selectedCountry),
              style: const TextStyle(
                fontSize: 18.0,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(width: 4.0),
            Text(
              selectedCountry.dialingCode,
              style: AppTextStyles.formInput.copyWith(
                color: enabled ? AppColors.textPrimary : AppColors.textDisabled,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCountryFlag(SupportedCountryCode country) {
    switch (country) {
      case SupportedCountryCode.peru:
        return '🇵🇪';
      case SupportedCountryCode.unitedStates:
        return '🇺🇸';
    }
  }
}

/// Country Picker Modal
class CountryPickerModal extends StatefulWidget {
  final SupportedCountryCode initialCountry;
  final ValueChanged<SupportedCountryCode> onCountrySelected;

  const CountryPickerModal({
    super.key,
    required this.initialCountry,
    required this.onCountrySelected,
  });

  @override
  State<CountryPickerModal> createState() => _CountryPickerModalState();
}

class _CountryPickerModalState extends State<CountryPickerModal> {
  late SupportedCountryCode _selectedCountry;

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.initialCountry;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250.0,
      padding: const EdgeInsets.only(top: 6.0),
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      color: AppColors.background,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.separator, width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancelar',
                      style: AppTextStyles.buttonTertiary.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text('Seleccionar país', style: AppTextStyles.headline),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      widget.onCountrySelected(_selectedCountry);
                      Navigator.of(context).pop();
                    },
                    child: Text('Listo', style: AppTextStyles.buttonTertiary),
                  ),
                ],
              ),
            ),
            // Country List
            Expanded(
              child: CupertinoPicker(
                magnification: 1.22,
                squeeze: 1.2,
                useMagnifier: true,
                itemExtent: 44.0,
                scrollController: FixedExtentScrollController(
                  initialItem: InternationalPhoneNumberDomainService
                      .supportedCountriesInPriorityOrder
                      .indexOf(_selectedCountry),
                ),
                onSelectedItemChanged: (int selectedItem) {
                  setState(() {
                    _selectedCountry = InternationalPhoneNumberDomainService
                        .supportedCountriesInPriorityOrder[selectedItem];
                  });
                },
                children: InternationalPhoneNumberDomainService
                    .supportedCountriesInPriorityOrder
                    .map(
                      (country) => Container(
                        alignment: Alignment.center,
                        height: 44.0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _getCountryFlag(country),
                              style: const TextStyle(
                                fontSize: 20.0,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Text(
                              country.countryDisplayName,
                              style: AppTextStyles.body,
                            ),
                            const SizedBox(width: 8.0),
                            Text(
                              country.dialingCode,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCountryFlag(SupportedCountryCode country) {
    switch (country) {
      case SupportedCountryCode.peru:
        return '🇵🇪';
      case SupportedCountryCode.unitedStates:
        return '🇺🇸';
    }
  }
}
