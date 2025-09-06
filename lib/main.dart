import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:ubiqa/services/0_config/shared/firebase_config.dart';
import 'package:ubiqa/services/5_injection/dependency_container.dart';
import 'package:ubiqa/ui/2_presentation/features/auth/flows/login_flow.dart';
import 'package:ubiqa/ui/2_presentation/features/auth/flows/registration_flow.dart';

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
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginFlow(),
        '/register': (context) => const RegistrationFlow(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

// Placeholder home page
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: const Center(child: Text('Welcome to Ubiqa!')));
  }
}
