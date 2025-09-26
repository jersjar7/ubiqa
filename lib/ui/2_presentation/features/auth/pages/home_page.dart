// lib/ui/2_presentation/features/auth/pages/home_page.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Import theme
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';

// Import pages
import 'profile_page.dart';

// Import state management
import '../../../../1_state/features/auth/auth_bloc.dart';
import '../../../../1_state/features/auth/auth_event.dart';
import '../../../../1_state/features/auth/auth_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return CupertinoPageScaffold(
          backgroundColor: AppColors.background,
          navigationBar: CupertinoNavigationBar(
            backgroundColor: AppColors.background,
            border: null,
            middle: Text('Ubiqa', style: AppTextStyles.headline),
            // Logout button on the right
            trailing: BlocListener<AuthBloc, AuthState>(
              listener: _handleAuthStateChanges,
              child: Builder(
                builder: (context) {
                  return CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _onLogoutPressed(context),
                    child: const Icon(CupertinoIcons.square_arrow_right),
                  );
                },
              ),
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/img/logos/oqupa-logo-tr-500x500.png',
                    width: 350.0,
                    height: 100.0,
                  ),
                  const SizedBox(height: 40.0),
                  Text(
                    'Alquila  ·  Compra  ·  Vende',
                    style: AppTextStyles.title2.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20.0),
                  Text(
                    'Bienvenido a Ubiqa\n\nTu plataforma para encontrar y anunciar\ntu propiedad perfecta en Piura',
                    style: AppTextStyles.callout.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60.0),
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    margin: const EdgeInsets.symmetric(horizontal: 40.0),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: AppColors.separator),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          CupertinoIcons.house_alt,
                          size: 40.0,
                          color: AppColors.accent,
                        ),
                        const SizedBox(height: 12.0),
                        Text(
                          'Próximamente',
                          style: AppTextStyles.headline.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'Funcionalidades de búsqueda y publicación de propiedades estarán disponibles pronto.',
                          style: AppTextStyles.footnote.copyWith(
                            color: AppColors.background,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40.0),
                  // Profile button in main content
                  if (state is AuthAuthenticated) ...[
                    CupertinoButton.filled(
                      onPressed: () => _onProfilePressed(context, state.user),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.person_circle, size: 20.0),
                          const SizedBox(width: 8.0),
                          Text('Ver mi perfil'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onProfilePressed(BuildContext context, dynamic user) {
    Navigator.of(
      context,
    ).push(CupertinoPageRoute(builder: (context) => ProfilePage(user: user)));
  }

  void _onLogoutPressed(BuildContext context) {
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

  void _handleAuthStateChanges(BuildContext context, AuthState state) {
    if (state is AuthUnauthenticated) {
      Navigator.of(context, rootNavigator: true).pushReplacementNamed('/login');
    } else if (state is AuthError) {
      _showErrorDialog(context, 'Error al cerrar sesión. Intenta de nuevo.');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
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
}
