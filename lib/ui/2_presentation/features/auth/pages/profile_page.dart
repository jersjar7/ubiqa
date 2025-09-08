// lib/ui/2_presentation/features/auth/pages/profile_page.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Import theme
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';

// Import widgets
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';

// Import state management
import '../../../../1_state/features/auth/auth_bloc.dart';
import '../../../../1_state/features/auth/auth_event.dart';
import '../../../../1_state/features/auth/auth_state.dart';

// Import domain entities
import '../../../../../models/1_domain/shared/entities/user.dart';
import '../../../../../models/1_domain/shared/value_objects/contact_info.dart';

class ProfilePage extends StatefulWidget {
  final User user;

  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _nameError;
  String? _emailError;
  String? _phoneError;

  bool _isEditing = false;
  ContactHours _selectedContactHours = ContactHours.anytime;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController.text = widget.user.name ?? '';
    _emailController.text = widget.user.email;
    _phoneController.text =
        widget
            .user
            .contactInfo
            ?.whatsappPhoneNumber
            .phoneNumberWithCountryCode ??
        '';
    _selectedContactHours =
        widget.user.contactInfo?.preferredContactTimeSlot ??
        ContactHours.anytime;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.background,
        border: null,
        middle: Text('Mi Perfil', style: AppTextStyles.headline),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.back),
        ),
        trailing: _isEditing
            ? null
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => setState(() => _isEditing = true),
                child: Text(
                  'Editar',
                  style: AppTextStyles.callout.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
      ),
      child: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          listener: _handleAuthStateChanges,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 32.0),
                _buildPersonalInfo(),
                const SizedBox(height: 24.0),
                _buildContactPreferences(),
                const SizedBox(height: 24.0),
                _buildSecuritySection(),
                const SizedBox(height: 32.0),
                _buildDangerZone(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 100.0,
              height: 100.0,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(50.0),
              ),
              child: Icon(
                CupertinoIcons.person_fill,
                size: 50.0,
                color: AppColors.background,
              ),
            ),
            if (_isEditing)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 32.0,
                  height: 32.0,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: AppColors.background, width: 2.0),
                  ),
                  child: Icon(
                    CupertinoIcons.camera_fill,
                    size: 16.0,
                    color: AppColors.background,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16.0),
        Text(widget.user.getDisplayName(), style: AppTextStyles.title2),
        const SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.user.isVerified()
                  ? CupertinoIcons.checkmark_seal_fill
                  : CupertinoIcons.exclamationmark_circle,
              size: 16.0,
              color: widget.user.isVerified()
                  ? AppColors.success
                  : AppColors.warning,
            ),
            const SizedBox(width: 6.0),
            Text(
              widget.user.isVerified()
                  ? 'Verificado'
                  : 'Pendiente verificación',
              style: AppTextStyles.caption1.copyWith(
                color: widget.user.isVerified()
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPersonalInfo() {
    return _buildSection(
      title: 'Información Personal',
      children: [
        FullNameTextField(
          controller: _nameController,
          errorText: _nameError,
          enabled: _isEditing,
          onChanged: _onNameChanged,
        ),
        const SizedBox(height: 16.0),
        AuthTextField(
          label: 'Correo electrónico',
          placeholder: 'Ingresa tu correo electrónico',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          errorText: _emailError,
          enabled: false, // Email cannot be changed
          prefix: Icon(
            CupertinoIcons.mail,
            size: 20.0,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16.0),
        // Phone field using AuthTextField
        AuthTextField(
          label: 'Número de teléfono',
          placeholder: 'Ingresa tu número de teléfono',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          errorText: _phoneError,
          enabled: _isEditing,
          prefix: Icon(
            CupertinoIcons.phone,
            size: 20.0,
            color: AppColors.textSecondary,
          ),
          onChanged: _onPhoneChanged,
        ),
        if (_isEditing) ...[
          const SizedBox(height: 24.0),
          Row(
            children: [
              Expanded(
                child: AuthButton(
                  text: 'Cancelar',
                  onPressed: _onCancelPressed,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: AuthButton(text: 'Guardar', onPressed: _onSavePressed),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildContactPreferences() {
    return _buildSection(
      title: 'Preferencias de Contacto',
      children: [
        _buildContactHoursSelector(),
        const SizedBox(height: 16.0),
        _buildWhatsAppInfo(),
      ],
    );
  }

  Widget _buildContactHoursSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Horario preferido', style: AppTextStyles.formLabel),
        const SizedBox(height: 8.0),
        SizedBox(
          height: 120.0,
          child: CupertinoPicker(
            itemExtent: 44.0,
            scrollController: FixedExtentScrollController(
              initialItem: ContactHours.values.indexOf(_selectedContactHours),
            ),
            onSelectedItemChanged: (index) {
              setState(() {
                _selectedContactHours = ContactHours.values[index];
              });
            },
            children: ContactHours.values.map((hours) {
              return Center(
                child: Text(
                  _getContactHoursText(hours),
                  style: AppTextStyles.body,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildWhatsAppInfo() {
    final phone =
        widget.user.contactInfo?.whatsappPhoneNumber.phoneNumberWithCountryCode;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.chat_bubble_fill,
            color: AppColors.success,
            size: 20.0,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WhatsApp habilitado',
                  style: AppTextStyles.callout.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (phone != null)
                  Text(
                    phone,
                    style: AppTextStyles.caption1.copyWith(
                      color: AppColors.success,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return _buildSection(
      title: 'Seguridad',
      children: [
        _buildSecurityItem(
          icon: CupertinoIcons.lock_shield,
          title: 'Cambiar contraseña',
          onTap: _onChangePasswordPressed,
        ),
        const SizedBox(height: 12.0),
        if (!widget.user.isVerified())
          _buildSecurityItem(
            icon: CupertinoIcons.phone_badge_plus,
            title: 'Verificar teléfono',
            subtitle: 'Verifica tu número para mayor seguridad',
            onTap: _onVerifyPhonePressed,
          ),
      ],
    );
  }

  Widget _buildDangerZone() {
    return _buildSection(
      title: 'Configuración de Cuenta',
      children: [
        AuthButton(
          text: 'Cerrar Sesión',
          width: double.infinity,
          onPressed: _onLogoutPressed,
        ),
        const SizedBox(height: 12.0),
        TextAuthButton(
          text: 'Eliminar cuenta',
          textColor: AppColors.error,
          onPressed: _onDeleteAccountPressed,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.headline),
        const SizedBox(height: 16.0),
        ...children,
      ],
    );
  }

  Widget _buildSecurityItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24.0),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.callout),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: AppTextStyles.caption1.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: AppColors.textSecondary,
              size: 16.0,
            ),
          ],
        ),
      ),
    );
  }

  // EVENT HANDLERS

  void _onNameChanged(String value) {
    if (_nameError != null) {
      setState(() => _nameError = null);
    }
  }

  void _onPhoneChanged(String value) {
    if (_phoneError != null) {
      setState(() => _phoneError = null);
    }
  }

  void _onCancelPressed() {
    _initializeControllers();
    setState(() => _isEditing = false);
  }

  void _onSavePressed() {
    _clearErrors();
    if (!_validateInputs()) return;

    context.read<AuthBloc>().add(
      UpdateProfileRequested(
        currentUser: widget.user,
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        preferredContactHours: _selectedContactHours,
      ),
    );
  }

  void _onChangePasswordPressed() {
    // TODO: Navigate to change password page
    _showComingSoonDialog('Cambio de contraseña');
  }

  void _onVerifyPhonePressed() {
    // TODO: Navigate to phone verification page
    Navigator.of(context).pushNamed('/verify-phone');
  }

  void _onLogoutPressed() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthBloc>().add(const LogoutRequested());
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  void _onDeleteAccountPressed() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Eliminar Cuenta'),
        content: const Text(
          'Esta acción es permanente. Toda tu información será eliminada.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthBloc>().add(
                DeleteAccountRequested(user: widget.user),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // VALIDATION

  void _clearErrors() {
    setState(() {
      _nameError = null;
      _phoneError = null;
    });
  }

  bool _validateInputs() {
    bool isValid = true;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'El nombre es requerido');
      isValid = false;
    }

    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty && !_isValidPeruPhone(phone)) {
      setState(() => _phoneError = 'Formato de teléfono peruano inválido');
      isValid = false;
    }

    return isValid;
  }

  bool _isValidPeruPhone(String phone) {
    return RegExp(
      r'^\+51[0-9]{9}$',
    ).hasMatch(phone.replaceAll(RegExp(r'[\s-]'), ''));
  }

  String _getContactHoursText(ContactHours hours) {
    switch (hours) {
      case ContactHours.morning:
        return 'Mañanas (8:00 - 12:00)';
      case ContactHours.afternoon:
        return 'Tardes (12:00 - 18:00)';
      case ContactHours.evening:
        return 'Noches (18:00 - 22:00)';
      case ContactHours.anytime:
        return 'Cualquier hora';
    }
  }

  // STATE MANAGEMENT

  void _handleAuthStateChanges(BuildContext context, AuthState state) {
    if (state is ProfileUpdateSuccess) {
      setState(() => _isEditing = false);
      _showSuccessDialog('Perfil actualizado correctamente');
    } else if (state is AuthUnauthenticated) {
      Navigator.of(context).pushReplacementNamed('/login');
    } else if (state is AccountDeletionSuccess) {
      Navigator.of(context).pushReplacementNamed('/login');
    } else if (state is AuthError) {
      _handleAuthError(state.message);
    }
  }

  void _handleAuthError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Éxito'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Próximamente'),
        content: Text('$feature estará disponible pronto.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
