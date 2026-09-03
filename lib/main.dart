import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/core/theme/app_theme.dart';
import 'package:gear_track/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:gear_track/feature/auth/presentation/widgets/auth_gate.dart';
import 'package:gear_track/feature/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:gear_track/feature/point_of_sale/presentation/bloc/pos_bloc.dart';
import 'package:gear_track/feature/receipt_verification/presentation/bloc/receipt_verification_bloc.dart';
import 'package:gear_track/feature/reports/presentation/bloc/reports_bloc.dart';
import 'package:gear_track/feature/returns/presentation/bloc/return_bloc.dart';
import 'package:gear_track/firebase_options.dart';
import 'package:gear_track/init_dependencies.dart';

void main() async {
  // Ensure Flutter's engine is fully initialized before calling native code
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await initDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              serviceLocator<AuthBloc>()..add(const AuthCheckRequested()),
        ),
        BlocProvider(create: (context) => serviceLocator<InventoryBloc>()),
        BlocProvider(create: (context) => serviceLocator<PosBloc>()),
        BlocProvider(
          create: (context) => serviceLocator<ReceiptVerificationBloc>(),
        ),
        BlocProvider(create: (context) => serviceLocator<ReportsBloc>()),
        BlocProvider(create: (context) => serviceLocator<ReturnBloc>()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Gear Track',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthGate(),
      ),
    );
  }
}
