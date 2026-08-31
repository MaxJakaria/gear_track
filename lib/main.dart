import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/core/theme/app_colors.dart';
import 'package:gear_track/feature/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:gear_track/feature/point_of_sale/presentation/bloc/pos_bloc.dart';
import 'package:gear_track/feature/receipt_verification/presentation/bloc/receipt_verification_bloc.dart';
import 'package:gear_track/feature/reports/presentation/bloc/reports_bloc.dart';
import 'package:gear_track/firebase_options.dart';
import 'package:gear_track/init_dependencies.dart';
import 'package:gear_track/core/pages/main_navigation_page.dart';

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
        BlocProvider(create: (context) => serviceLocator<InventoryBloc>()),
        BlocProvider(create: (context) => serviceLocator<PosBloc>()),
        BlocProvider(
          create: (context) => serviceLocator<ReceiptVerificationBloc>(),
        ),
        BlocProvider(create: (context) => serviceLocator<ReportsBloc>()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Gear Track',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryButtonLight,
            brightness: Brightness.light,
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryButtonLight,
              foregroundColor: AppColors.buttonForeground,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryButtonLight,
              foregroundColor: AppColors.buttonForeground,
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: AppColors.primaryButtonLight,
            foregroundColor: AppColors.buttonForeground,
          ),
          inputDecorationTheme: const InputDecorationTheme(
            prefixIconConstraints: BoxConstraints(minWidth: 36, minHeight: 0),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryButtonDark,
            brightness: Brightness.dark,
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryButtonDark,
              foregroundColor: AppColors.buttonForeground,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryButtonDark,
              foregroundColor: AppColors.buttonForeground,
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: AppColors.primaryButtonDark,
            foregroundColor: AppColors.buttonForeground,
          ),
          inputDecorationTheme: const InputDecorationTheme(
            prefixIconConstraints: BoxConstraints(minWidth: 36, minHeight: 0),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        themeMode: ThemeMode.system,
        home: const MainNavigationPage(),
      ),
    );
  }
}
