// lib/ui/2_presentation/features/auth/pages/auth_check_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ubiqa/services/5_injection/dependency_container.dart';
import 'package:ubiqa/ui/1_state/features/auth/auth_bloc.dart';
import 'package:ubiqa/ui/1_state/features/auth/auth_event.dart';
import 'package:ubiqa/ui/1_state/features/auth/auth_state.dart';

class AuthCheckPage extends StatelessWidget {
  const AuthCheckPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          UbiqaDependencyContainer.get<AuthBloc>()
            ..add(const GetCurrentUserRequested()),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.of(context).pushReplacementNamed('/home');
          } else if (state is AuthUnauthenticated) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        },
        child: const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
    );
  }
}
