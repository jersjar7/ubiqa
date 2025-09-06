import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:ubiqa/services/0_config/shared/firebase_config.dart';
import 'package:ubiqa/services/5_injection/dependency_container.dart';
import 'package:ubiqa/ui/2_presentation/features/auth/pages/login_page.dart';

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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const LoginPage(),
    );
  }
}
