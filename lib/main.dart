// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/di.dart' as di;
import 'package:google_fonts/google_fonts.dart';
import 'core/database/database_helper.dart';
import 'core/session/session_manager.dart';
import 'core/settings/settings_notifier.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'features/dashboard/presentation/pages/dashboard_screen.dart' as dashboard;
import 'features/booking/presentation/pages/booking_list_screen.dart' as bookings;
import 'features/auth/presentation/pages/login_screen.dart' as auth;
import 'features/settings/presentation/screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Prevent google_fonts from attempting to fetch fonts over the network at runtime
  GoogleFonts.config.allowRuntimeFetching = false;

  // Initialize dependency injection container
  await di.init();

  // Initialize session manager
  await SessionManager.instance.init();

  // Ensure the admin user exists
  await DatabaseHelper().seedAdminUser();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsNotifier()..loadThemeMode()),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider()..loadCurrentUser(),
        ),
      ],
      child: const ArenaManagerApp(),
    ),
  );
}

class ArenaManagerApp extends StatefulWidget {
  const ArenaManagerApp({super.key});

  @override
  State<ArenaManagerApp> createState() => _ArenaManagerAppState();
}

class _ArenaManagerAppState extends State<ArenaManagerApp> {
  ThemeMode get _themeMode => Provider.of<SettingsNotifier>(context).themeMode;



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ArenaManager',

      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: _themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const auth.LoginScreen(),
        '/dashboard': (context) => const dashboard.DashboardScreen(),
        '/bookings': (context) => const bookings.BookingListScreenWarp(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}