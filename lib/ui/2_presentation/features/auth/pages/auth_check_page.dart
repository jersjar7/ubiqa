// lib/ui/2_presentation/features/auth/pages/auth_check_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ubiqa/ui/1_state/features/auth/auth_bloc.dart';
import 'package:ubiqa/ui/1_state/features/auth/auth_event.dart';
import 'package:ubiqa/ui/1_state/features/auth/auth_state.dart';

class AuthCheckPage extends StatefulWidget {
  const AuthCheckPage({super.key});

  @override
  State<AuthCheckPage> createState() => _AuthCheckPageState();
}

class _AuthCheckPageState extends State<AuthCheckPage> {
  @override
  void initState() {
    super.initState();
    print('🔄 AuthCheckPage: initState called');

    // Trigger current user check when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔄 AuthCheckPage: Triggering GetCurrentUserRequested');
      context.read<AuthBloc>().add(const GetCurrentUserRequested());
    });
  }

  @override
  Widget build(BuildContext context) {
    print('🔄 AuthCheckPage: build called');

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        print('🔄 AuthCheckPage: State changed to ${state.runtimeType}');

        if (state is AuthAuthenticated) {
          print('✅ AuthCheckPage: User authenticated, navigating to home');
          Navigator.of(context).pushReplacementNamed('/home');
        } else if (state is AuthUnauthenticated) {
          print('❌ AuthCheckPage: User not authenticated, navigating to login');
          Navigator.of(context).pushReplacementNamed('/login');
        } else if (state is AuthError) {
          print('🚨 AuthCheckPage: Auth error - ${state.message}');
          // For debugging, let's navigate to login on error
          Navigator.of(context).pushReplacementNamed('/login');
        }
      },
      builder: (context, state) {
        print('🔄 AuthCheckPage: Building with state ${state.runtimeType}');

        // Show different UI based on state for debugging
        if (state is AuthLoading) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Checking authentication...'),
                  SizedBox(height: 8),
                  Text('State: AuthLoading', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          );
        } else if (state is AuthError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Authentication Error'),
                  SizedBox(height: 8),
                  Text(state.message, textAlign: TextAlign.center),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.of(context).pushReplacementNamed('/login'),
                    child: Text('Go to Login'),
                  ),
                ],
              ),
            ),
          );
        } else {
          // For any other state, show loading
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing...'),
                  SizedBox(height: 8),
                  Text(
                    'State: ${state.runtimeType}',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
