import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ubiqa/services/0_config/shared/firebase_config.dart';
import 'package:ubiqa/services/0_config/shared/secrets.dart';
import 'package:ubiqa/services/5_injection/dependency_container.dart';
import 'package:ubiqa/ui/1_state/features/auth/auth_bloc.dart';
import 'package:ubiqa/ui/2_presentation/features/auth/flows/login_flow.dart';
import 'package:ubiqa/ui/2_presentation/features/auth/flows/registration_flow.dart';
import 'package:ubiqa/ui/2_presentation/features/auth/pages/auth_check_page.dart';
import 'package:ubiqa/ui/2_presentation/features/listings/pages/home_page.dart';

Future<void> main() async {
  // Ensure Flutter binding is initialized before async operations
  WidgetsFlutterBinding.ensureInitialized();

  // Load all environment variables from .env file
  await Secrets.initialize();

  await FirebaseConfig.initialize();
  await UbiqaDependencyContainer.initializeHorizontalFoundation();
  await UbiqaDependencyContainer.initializeVerticalFeatures();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Create AuthBloc at app level to persist across navigation
      create: (context) => UbiqaDependencyContainer.get<AuthBloc>(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Ubiqa',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthCheckPage(),
          '/login': (context) => const LoginFlow(),
          '/register': (context) => const RegistrationFlow(),
          '/home': (context) => const HomePage(),
        },
      ),
    );
  }
}
