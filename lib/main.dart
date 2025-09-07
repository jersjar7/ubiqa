import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:ubiqa/services/0_config/shared/firebase_config.dart';
import 'package:ubiqa/services/5_injection/dependency_container.dart';
import 'package:ubiqa/ui/2_presentation/features/auth/flows/login_flow.dart';
import 'package:ubiqa/ui/2_presentation/features/auth/flows/registration_flow.dart';
import 'package:ubiqa/ui/2_presentation/features/auth/pages/auth_check_page.dart';
import 'package:ubiqa/ui/2_presentation/features/auth/pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initialize();
  await UbiqaDependencyContainer.initializeHorizontalFoundation();
  await UbiqaDependencyContainer.initializeVerticalFeatures();
  debugPaintBaselinesEnabled = false;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
    );
  }
}
