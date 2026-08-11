import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gear_track/firebase_options.dart';

void main() async {
  // Ensure Flutter's engine is fully initialized before calling native code
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gear Track',
      home: Scaffold(),
    );
  }
}
