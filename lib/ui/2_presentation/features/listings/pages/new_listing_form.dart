// lib/ui/2_presentation/features/listings/pages/new_listing_form.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ubiqa/models/1_domain/shared/entities/property.dart';
import 'package:ubiqa/models/1_domain/shared/value_objects/price.dart';

// Import theme
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';

// Import domain
import '../../../../../models/1_domain/domain_orchestrator.dart';

/// New Listing Form Page
///
/// Allows users to create a new property listing by entering:
/// - Property details (type, operation, specs)
/// - Location information
/// - Listing details (title, description, price)
/// - Contact preferences
///
/// Form validates all inputs before submission.
class NewListingFormPage extends StatefulWidget {
  const NewListingFormPage({super.key});

  @override
  State<NewListingFormPage> createState() => _NewListingFormPageState();
}

class _NewListingFormPageState extends State<NewListingFormPage> {
  // Form Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _areaController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _parkingController = TextEditingController();
  final _addressController = TextEditingController();
  final _districtController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  // Focus Nodes
  final _titleFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  final _priceFocusNode = FocusNode();
  final _areaFocusNode = FocusNode();
  final _bedroomsFocusNode = FocusNode();
  final _bathroomsFocusNode = FocusNode();
  final _parkingFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();
  final _districtFocusNode = FocusNode();
  final _latitudeFocusNode = FocusNode();
  final _longitudeFocusNode = FocusNode();

  // Error States
  String? _titleError;
  String? _descriptionError;
  String? _priceError;
  String? _areaError;
  String? _bedroomsError;
  String? _bathroomsError;
  String? _parkingError;
  String? _addressError;
  String? _districtError;
  String? _latitudeError;
  String? _longitudeError;

  // Selection States
  PropertyType _selectedPropertyType = PropertyType.casa;
  OperationType _selectedOperationType = OperationType.venta;
  Currency _selectedCurrency = Currency.pen;
  List<String> _selectedAmenities = [];

  // Form State
  bool _isSubmitting = false;

  @override
  void dispose() {
    // Dispose controllers
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _areaController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _parkingController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();

    // Dispose focus nodes
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _priceFocusNode.dispose();
    _areaFocusNode.dispose();
    _bedroomsFocusNode.dispose();
    _bathroomsFocusNode.dispose();
    _parkingFocusNode.dispose();
    _addressFocusNode.dispose();
    _districtFocusNode.dispose();
    _latitudeFocusNode.dispose();
    _longitudeFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.background,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.back),
        ),
        middle: Text('Publicar Propiedad', style: AppTextStyles.headline),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24.0),
              _buildSectionHeader('Tipo de Propiedad'),
              const SizedBox(height: 12.0),
              _buildPropertyTypeSelector(),
              const SizedBox(height: 24.0),
              _buildSectionHeader('Tipo de Operación'),
              const SizedBox(height: 12.0),
              _buildOperationTypeSelector(),
              const SizedBox(height: 24.0),
              _buildSectionHeader('Información Básica'),
              const SizedBox(height: 12.0),
              _buildTitleField(),
              const SizedBox(height: 16.0),
              _buildDescriptionField(),
              const SizedBox(height: 24.0),
              _buildSectionHeader('Precio'),
              const SizedBox(height: 12.0),
              _buildPriceFields(),
              const SizedBox(height: 24.0),
              _buildSectionHeader('Especificaciones'),
              const SizedBox(height: 12.0),
              _buildSpecificationsFields(),
              const SizedBox(height: 24.0),
              _buildSectionHeader('Ubicación'),
              const SizedBox(height: 12.0),
              _buildLocationFields(),
              const SizedBox(height: 24.0),
              _buildSectionHeader('Comodidades (Opcional)'),
              const SizedBox(height: 12.0),
              _buildAmenitiesSection(),
              const SizedBox(height: 32.0),
              _buildSubmitButton(),
              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }

  // SECTION HEADERS

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  // PROPERTY TYPE SELECTOR

  Widget _buildPropertyTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: CupertinoSegmentedControl<PropertyType>(
        groupValue: _selectedPropertyType,
        onValueChanged: (PropertyType value) {
          setState(() {
            _selectedPropertyType = value;
            // Clear bedroom/bathroom fields if switching to non-residential
            if (!value.hasRooms) {
              _bedroomsController.clear();
              _bathroomsController.clear();
              _bedroomsError = null;
              _bathroomsError = null;
            }
          });
        },
        children: {
          PropertyType.casa: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text('Casa', style: AppTextStyles.body),
          ),
          PropertyType.departamento: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text('Depto', style: AppTextStyles.body),
          ),
          PropertyType.terreno: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text('Terreno', style: AppTextStyles.body),
          ),
          PropertyType.oficina: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text('Local', style: AppTextStyles.body),
          ),
        },
      ),
    );
  }

  // OPERATION TYPE SELECTOR

  Widget _buildOperationTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: CupertinoSegmentedControl<OperationType>(
        groupValue: _selectedOperationType,
        onValueChanged: (OperationType value) {
          setState(() => _selectedOperationType = value);
        },
        children: {
          OperationType.venta: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text('Venta', style: AppTextStyles.body),
          ),
          OperationType.alquiler: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text('Alquiler', style: AppTextStyles.body),
          ),
        },
      ),
    );
  }

  // BASIC INFORMATION FIELDS

  Widget _buildTitleField() {
    return _buildTextField(
      label: 'Título del Anuncio',
      placeholder: 'Ej: Casa amplia en zona residencial',
      controller: _titleController,
      focusNode: _titleFocusNode,
      errorText: _titleError,
      maxLength: 100,
      onChanged: (value) => setState(() => _titleError = null),
    );
  }

  Widget _buildDescriptionField() {
    return _buildTextField(
      label: 'Descripción',
      placeholder: 'Describe las características de tu propiedad...',
      controller: _descriptionController,
      focusNode: _descriptionFocusNode,
      errorText: _descriptionError,
      maxLines: 5,
      maxLength: 500,
      onChanged: (value) => setState(() => _descriptionError = null),
    );
  }

  // PRICE FIELDS

  Widget _buildPriceFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildTextField(
                label: 'Monto',
                placeholder: '0.00',
                controller: _priceController,
                focusNode: _priceFocusNode,
                errorText: _priceError,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                onChanged: (value) => setState(() => _priceError = null),
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: _buildCurrencySelector(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Moneda', style: AppTextStyles.formLabel),
        const SizedBox(height: 6.0),
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: AppColors.border, width: 1.0),
          ),
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            onPressed: () => _showCurrencyPicker(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedCurrency.currencySymbol,
                  style: AppTextStyles.body,
                ),
                const Icon(
                  CupertinoIcons.chevron_down,
                  size: 16.0,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCurrencyPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 200,
          color: AppColors.background,
          child: Column(
            children: [
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    CupertinoButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Listo'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 40.0,
                  onSelectedItemChanged: (int index) {
                    setState(() {
                      _selectedCurrency = Currency.values[index];
                    });
                  },
                  children: Currency.values.map((currency) {
                    return Center(
                      child: Text(
                        '${currency.currencySymbol} - ${currency.currencySymbol}',
                        style: AppTextStyles.body,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // SPECIFICATIONS FIELDS

  Widget _buildSpecificationsFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          label: 'Área Total (m²)',
          placeholder: 'Ej: 120',
          controller: _areaController,
          focusNode: _areaFocusNode,
          errorText: _areaError,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          onChanged: (value) => setState(() => _areaError = null),
        ),
        if (_selectedPropertyType.hasRooms) ...[
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'Dormitorios',
                  placeholder: '0',
                  controller: _bedroomsController,
                  focusNode: _bedroomsFocusNode,
                  errorText: _bedroomsError,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) => setState(() => _bedroomsError = null),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: _buildTextField(
                  label: 'Baños',
                  placeholder: '0',
                  controller: _bathroomsController,
                  focusNode: _bathroomsFocusNode,
                  errorText: _bathroomsError,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) => setState(() => _bathroomsError = null),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16.0),
        _buildTextField(
          label: 'Estacionamientos',
          placeholder: '0',
          controller: _parkingController,
          focusNode: _parkingFocusNode,
          errorText: _parkingError,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) => setState(() => _parkingError = null),
        ),
      ],
    );
  }

  // LOCATION FIELDS

  Widget _buildLocationFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          label: 'Dirección',
          placeholder: 'Ej: Av. Grau 123',
          controller: _addressController,
          focusNode: _addressFocusNode,
          errorText: _addressError,
          onChanged: (value) => setState(() => _addressError = null),
        ),
        const SizedBox(height: 16.0),
        _buildTextField(
          label: 'Distrito',
          placeholder: 'Ej: Piura',
          controller: _districtController,
          focusNode: _districtFocusNode,
          errorText: _districtError,
          onChanged: (value) => setState(() => _districtError = null),
        ),
        const SizedBox(height: 16.0),
        Text(
          'Coordenadas GPS (Opcional)',
          style: AppTextStyles.formLabel.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14.0,
          ),
        ),
        const SizedBox(height: 8.0),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Latitud',
                placeholder: '-5.0645',
                controller: _latitudeController,
                focusNode: _latitudeFocusNode,
                errorText: _latitudeError,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d+\.?\d{0,8}')),
                ],
                onChanged: (value) => setState(() => _latitudeError = null),
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: _buildTextField(
                label: 'Longitud',
                placeholder: '-80.4328',
                controller: _longitudeController,
                focusNode: _longitudeFocusNode,
                errorText: _longitudeError,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d+\.?\d{0,8}')),
                ],
                onChanged: (value) => setState(() => _longitudeError = null),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // AMENITIES SECTION

  Widget _buildAmenitiesSection() {
    final commonAmenities = [
      'Piscina',
      'Jardín',
      'Balcón',
      'Ascensor',
      'Gimnasio',
      'Seguridad 24h',
      'Portería',
      'Área de juegos',
      'Cocina equipada',
      'Lavandería',
    ];

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: commonAmenities.map((amenity) {
        final isSelected = _selectedAmenities.contains(amenity);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedAmenities.remove(amenity);
              } else {
                _selectedAmenities.add(amenity);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.backgroundSecondary,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Text(
              amenity,
              style: TextStyle(
                fontSize: 14.0,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // SUBMIT BUTTON

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12.0),
        onPressed: _isSubmitting ? null : _handleSubmitListing,
        child: _isSubmitting
            ? const CupertinoActivityIndicator(color: Colors.white)
            : const Text(
                'Publicar Propiedad',
                style: TextStyle(
                  fontSize: 17.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // FORM VALIDATION AND SUBMISSION

  Future<void> _handleSubmitListing() async {
    if (!_validateForm()) {
      return;
    }

    setState(() => _isSubmitting = true);

    // TODO: Implement listing creation logic when BLoC is ready
    // For now, show success message
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isSubmitting = false);
      _showSuccessDialog();
    }
  }

  bool _validateForm() {
    bool isValid = true;

    // Validate title
    if (_titleController.text.trim().isEmpty) {
      setState(() => _titleError = 'El título es requerido');
      isValid = false;
    } else if (_titleController.text.trim().length < 10) {
      setState(() => _titleError = 'El título debe tener al menos 10 caracteres');
      isValid = false;
    }

    // Validate description
    if (_descriptionController.text.trim().isEmpty) {
      setState(() => _descriptionError = 'La descripción es requerida');
      isValid = false;
    } else if (_descriptionController.text.trim().length < 20) {
      setState(
        () => _descriptionError = 'La descripción debe tener al menos 20 caracteres',
      );
      isValid = false;
    }

    // Validate price
    if (_priceController.text.trim().isEmpty) {
      setState(() => _priceError = 'El precio es requerido');
      isValid = false;
    } else {
      final price = double.tryParse(_priceController.text);
      if (price == null || price <= 0) {
        setState(() => _priceError = 'Ingresa un precio válido');
        isValid = false;
      }
    }

    // Validate area
    if (_areaController.text.trim().isEmpty) {
      setState(() => _areaError = 'El área es requerida');
      isValid = false;
    } else {
      final area = double.tryParse(_areaController.text);
      if (area == null || area <= 0) {
        setState(() => _areaError = 'Ingresa un área válida');
        isValid = false;
      }
    }

    // Validate bedrooms/bathrooms for residential properties
    if (_selectedPropertyType.hasRooms) {
      if (_bedroomsController.text.trim().isEmpty) {
        setState(() => _bedroomsError = 'Los dormitorios son requeridos');
        isValid = false;
      }
      if (_bathroomsController.text.trim().isEmpty) {
        setState(() => _bathroomsError = 'Los baños son requeridos');
        isValid = false;
      }
    }

    // Validate address
    if (_addressController.text.trim().isEmpty) {
      setState(() => _addressError = 'La dirección es requerida');
      isValid = false;
    }

    // Validate district
    if (_districtController.text.trim().isEmpty) {
      setState(() => _districtError = 'El distrito es requerido');
      isValid = false;
    }

    return isValid;
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('¡Éxito!'),
        content: const Text(
          'Tu propiedad ha sido publicada exitosamente. '
          'Pronto aparecerá en el mapa.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to previous screen
            },
          ),
        ],
      ),
    );
  }

  // REUSABLE TEXT FIELD BUILDER

  Widget _buildTextField({
    required String label,
    required String placeholder,
    required TextEditingController controller,
    required FocusNode focusNode,
    String? errorText,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    int? maxLength,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.formLabel),
        const SizedBox(height: 6.0),
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: errorText != null ? AppColors.error : AppColors.border,
              width: errorText != null ? 2.0 : 1.0,
            ),
          ),
          child: CupertinoTextField(
            controller: controller,
            focusNode: focusNode,
            placeholder: placeholder,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            maxLines: maxLines,
            maxLength: maxLength,
            style: AppTextStyles.formInput,
            placeholderStyle: AppTextStyles.formPlaceholder,
            decoration: const BoxDecoration(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            onChanged: onChanged,
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4.0),
          Text(
            errorText,
            style: const TextStyle(
              fontSize: 13.0,
              color: AppColors.error,
            ),
          ),
        ],
      ],
    );
  }
}