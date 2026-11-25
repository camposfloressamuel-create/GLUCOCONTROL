import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'notifications/notification_service.dart';
import 'providers/gluco_provider.dart';
import 'screens/home_shell.dart';
import 'screens/welcome_screen.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  try {
    await NotificationService.instance.initialize();
  } catch (_) {
    // Si las notificaciones fallan al inicializar en algún entorno, la app sigue operando localmente.
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => GlucoProvider()..initialize(),
      child: const GlucoControlApp(),
    ),
  );
}

class GlucoControlApp extends StatelessWidget {
  const GlucoControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('es'),
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const _RootRouter(),
    );
  }
}

class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GlucoProvider>();
    if (provider.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.lightGreen,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primaryGreen),
              SizedBox(height: 16),
              Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!provider.onboardingCompleted || provider.profile == null) {
      return const WelcomeScreen();
    }

    return const HomeShell();
  }
}
