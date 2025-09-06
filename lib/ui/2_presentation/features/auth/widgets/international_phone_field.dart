// lib/ui/2_presentation/features/auth/widgets/international_phone_field.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../../../../models/1_domain/shared/value_objects/international_phone_number.dart';
import 'auth_text_field.dart';
import 'country_selector_widget.dart';

/// International Phone Field Widget
class InternationalPhoneField extends StatefulWidget {
  final String? label;
  final String? errorText;
  final SupportedCountryCode initialCountry;
  final String? initialPhoneNumber;
  final ValueChanged<String>? onPhoneChanged;
  final ValueChanged<SupportedCountryCode>? onCountryChanged;
  final bool enabled;

  const InternationalPhoneField({
    super.key,
    this.label,
    this.errorText,
    this.initialCountry = SupportedCountryCode.peru,
    this.initialPhoneNumber,
    this.onPhoneChanged,
    this.onCountryChanged,
    this.enabled = true,
  });

  @override
  State<InternationalPhoneField> createState() =>
      _InternationalPhoneFieldState();
}

class _InternationalPhoneFieldState extends State<InternationalPhoneField> {
  late SupportedCountryCode _selectedCountry;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.initialCountry;
    _phoneController = TextEditingController();

    if (widget.initialPhoneNumber != null) {
      _phoneController.text = _extractLocalNumber(widget.initialPhoneNumber!);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      label: widget.label ?? 'Número de teléfono',
      placeholder: _getPlaceholderForCountry(_selectedCountry),
      errorText: widget.errorText,
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      enabled: widget.enabled,
      inputFormatters: _getInputFormattersForCountry(_selectedCountry),
      prefix: CompactCountrySelector(
        selectedCountry: _selectedCountry,
        enabled: widget.enabled,
        onTap: widget.enabled ? _showCountryPicker : null,
      ),
      onChanged: _onPhoneNumberChanged,
    );
  }

  void _showCountryPicker() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CountryPickerModal(
        initialCountry: _selectedCountry,
        onCountrySelected: _onCountryChanged,
      ),
    );
  }

  void _onCountryChanged(SupportedCountryCode country) {
    setState(() {
      _selectedCountry = country;
    });

    // Clear phone number when country changes
    _phoneController.clear();

    widget.onCountryChanged?.call(country);
    _onPhoneNumberChanged('');
  }

  void _onPhoneNumberChanged(String localNumber) {
    final fullPhoneNumber = _buildFullPhoneNumber(localNumber);
    widget.onPhoneChanged?.call(fullPhoneNumber);
  }

  String _buildFullPhoneNumber(String localNumber) {
    if (localNumber.isEmpty) return '';

    final cleanedLocal = localNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanedLocal.isEmpty) return '';

    return '${_selectedCountry.dialingCode}$cleanedLocal';
  }

  String _extractLocalNumber(String fullPhoneNumber) {
    for (final country in SupportedCountryCode.values) {
      if (fullPhoneNumber.startsWith(country.dialingCode)) {
        return fullPhoneNumber.substring(country.dialingCode.length);
      }
    }
    return fullPhoneNumber;
  }

  String _getPlaceholderForCountry(SupportedCountryCode country) {
    switch (country) {
      case SupportedCountryCode.peru:
        return '987 654 321';
      case SupportedCountryCode.unitedStates:
        return '(555) 123-4567';
    }
  }

  List<TextInputFormatter> _getInputFormattersForCountry(
    SupportedCountryCode country,
  ) {
    switch (country) {
      case SupportedCountryCode.peru:
        return [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(9),
          _PeruPhoneFormatter(),
        ];
      case SupportedCountryCode.unitedStates:
        return [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
          _USPhoneFormatter(),
        ];
    }
  }
}

/// Format Peru phone numbers as user types (987 654 321)
class _PeruPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (text.length <= 3) {
      return newValue.copyWith(text: text);
    } else if (text.length <= 6) {
      return newValue.copyWith(
        text: '${text.substring(0, 3)} ${text.substring(3)}',
        selection: TextSelection.collapsed(offset: text.length + 1),
      );
    } else if (text.length <= 9) {
      return newValue.copyWith(
        text:
            '${text.substring(0, 3)} ${text.substring(3, 6)} ${text.substring(6)}',
        selection: TextSelection.collapsed(offset: text.length + 2),
      );
    }

    return oldValue;
  }
}

/// Format US phone numbers as user types ((555) 123-4567)
class _USPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (text.length <= 3) {
      return newValue.copyWith(text: text);
    } else if (text.length <= 6) {
      return newValue.copyWith(
        text: '(${text.substring(0, 3)}) ${text.substring(3)}',
        selection: TextSelection.collapsed(offset: text.length + 3),
      );
    } else if (text.length <= 10) {
      return newValue.copyWith(
        text:
            '(${text.substring(0, 3)}) ${text.substring(3, 6)}-${text.substring(6)}',
        selection: TextSelection.collapsed(offset: text.length + 4),
      );
    }

    return oldValue;
  }
}
