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
  final FocusNode? focusNode; // Add focus node support
  final ValueChanged<String>? onPhoneChanged;
  final ValueChanged<SupportedCountryCode>? onCountryChanged;
  final ValueChanged<String>? onSubmitted; // Add onSubmitted support
  final bool enabled;

  const InternationalPhoneField({
    super.key,
    this.label,
    this.errorText,
    this.initialCountry = SupportedCountryCode.peru,
    this.initialPhoneNumber,
    this.focusNode,
    this.onPhoneChanged,
    this.onCountryChanged,
    this.onSubmitted,
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
      focusNode: widget.focusNode, // Pass focus node
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      enabled: widget.enabled,
      inputFormatters: _getInputFormattersForCountry(_selectedCountry),
      prefix: CompactCountrySelector(
        selectedCountry: _selectedCountry,
        enabled: widget.enabled,
        onTap: widget.enabled ? _showCountrySelector : null,
      ),
      onChanged: _onPhoneNumberChanged,
      onSubmitted: widget.onSubmitted, // Pass onSubmitted
    );
  }

  void _onPhoneNumberChanged(String value) {
    final fullNumber = _selectedCountry.dialingCode + value.replaceAll(' ', '');
    widget.onPhoneChanged?.call(fullNumber);
  }

  void _showCountrySelector() {
    showCupertinoModalPopup<SupportedCountryCode>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Seleccionar país'),
        actions: SupportedCountryCode.values.map((country) {
          return CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop(country);
            },
            child: Row(
              children: [
                Text(
                  _getCountryFlag(country),
                  style: const TextStyle(fontSize: 20.0),
                ),
                const SizedBox(width: 12.0),
                Text(_getCountryName(country)),
                const Spacer(),
                Text(
                  country.dialingCode,
                  style: const TextStyle(color: CupertinoColors.systemGrey),
                ),
              ],
            ),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ),
    ).then((selectedCountry) {
      if (selectedCountry != null && selectedCountry != _selectedCountry) {
        setState(() {
          _selectedCountry = selectedCountry;
        });
        widget.onCountryChanged?.call(selectedCountry);
        _onPhoneNumberChanged(_phoneController.text);
      }
    });
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

  String _getCountryFlag(SupportedCountryCode country) {
    switch (country) {
      case SupportedCountryCode.peru:
        return '🇵🇪';
      case SupportedCountryCode.unitedStates:
        return '🇺🇸';
    }
  }

  String _getCountryName(SupportedCountryCode country) {
    switch (country) {
      case SupportedCountryCode.peru:
        return 'Perú';
      case SupportedCountryCode.unitedStates:
        return 'Estados Unidos';
    }
  }
}

/// Peru phone number formatter (XXX XXX XXX)
class _PeruPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;
    if (newText.length <= 3) {
      return newValue;
    } else if (newText.length <= 6) {
      return TextEditingValue(
        text: '${newText.substring(0, 3)} ${newText.substring(3)}',
        selection: TextSelection.collapsed(offset: newText.length + 1),
      );
    } else {
      return TextEditingValue(
        text:
            '${newText.substring(0, 3)} ${newText.substring(3, 6)} ${newText.substring(6)}',
        selection: TextSelection.collapsed(offset: newText.length + 2),
      );
    }
  }
}

/// US phone number formatter ((XXX) XXX-XXXX)
class _USPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;
    if (newText.length <= 3) {
      return TextEditingValue(
        text: newText.isEmpty ? '' : '($newText',
        selection: TextSelection.collapsed(offset: newText.length + 1),
      );
    } else if (newText.length <= 6) {
      return TextEditingValue(
        text: '(${newText.substring(0, 3)}) ${newText.substring(3)}',
        selection: TextSelection.collapsed(offset: newText.length + 3),
      );
    } else {
      return TextEditingValue(
        text:
            '(${newText.substring(0, 3)}) ${newText.substring(3, 6)}-${newText.substring(6)}',
        selection: TextSelection.collapsed(offset: newText.length + 4),
      );
    }
  }
}
