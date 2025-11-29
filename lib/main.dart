// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/di.dart' as di;
import 'core/database/database_helper.dart';
import 'core/session/session_manager.dart';
import 'providers/auth_provider.dart';
import 'features/dashboard/presentation/pages/dashboard_screen.dart' as dashboard;
import 'features/booking/presentation/pages/booking_list_screen.dart' as bookings;
import 'features/auth/presentation/pages/login_screen.dart' as auth;
import 'features/settings/presentation/screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection container
  await di.init();

  // Initialize session manager
  await SessionManager.instance.init();

  // Ensure the admin user exists
  await DatabaseHelper().seedAdminUser();

  runApp(
    MultiProvider(
      providers: [
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
  ThemeMode _themeMode = ThemeMode.light;

  ThemeData get _lightTheme => ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.green,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true),
      );

  ThemeData get _darkTheme => ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true),
      );

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
      theme: _lightTheme,
      darkTheme: _darkTheme,
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
// // ignore_for_file: depend_on_referenced_packages

// import 'package:flutter/material.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:provider/provider.dart';

// import 'core/di.dart' as di;
// import 'core/database/database_helper.dart';
// import 'core/session/session_manager.dart';
// import 'providers/auth_provider.dart';
// import 'features/admin/presentation/screens/admin_dashboard_screen.dart' as admin;
// import 'features/auth/presentation/pages/login_screen.dart' as auth;

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Initialize dependency injection container
//   await di.init();

//   // Initialize session manager (reads SharedPreferences)
//   await SessionManager.instance.init();

//   // Ensure seed initial data exists
//   await DatabaseHelper().seedAdminUser();

//   final bool loggedIn = SessionManager.instance.isLoggedIn;

//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider<AuthProvider>(
//           create: (_) => AuthProvider()..loadCurrentUser(),
//         ),
//         // Add other providers here
//       ],
//       child: MyApp(initialRouteIsDashboard: loggedIn),
//     ),
//   );
// }

// class MyApp extends StatefulWidget {
//   final bool initialRouteIsDashboard;

//   const MyApp({required this.initialRouteIsDashboard, super.key});

//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   ThemeMode _themeMode = ThemeMode.light;

//   void _toggleTheme() {
//     setState(() {
//       _themeMode =
//           _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
//     });
//   }

//   ThemeData get _lightTheme => ThemeData(
//         brightness: Brightness.light,
//         primarySwatch: Colors.green,
//         useMaterial3: true,
//         appBarTheme: const AppBarTheme(centerTitle: true),
//       );

//   ThemeData get _darkTheme => ThemeData(
//         brightness: Brightness.dark,
//         primarySwatch: Colors.green,
//         useMaterial3: true,
//         appBarTheme: const AppBarTheme(centerTitle: true),
//       );

//   @override
//   Widget build(BuildContext context) {
//     final initialRoute = widget.initialRouteIsDashboard
//         ? '/dashboard'
//         : '/login';

//     return MaterialApp(
//       title: 'Arena Manager',
//       debugShowCheckedModeBanner: false,
//       locale: const Locale('ar'),
//       supportedLocales: const [Locale('ar'), Locale('en')],
//       localizationsDelegates: const [
//         GlobalMaterialLocalizations.delegate,
//         GlobalWidgetsLocalizations.delegate,
//         GlobalCupertinoLocalizations.delegate,
//       ],
//       themeMode: _themeMode,
//       theme: _lightTheme,
//       darkTheme: _darkTheme,
//       initialRoute: initialRoute,
//       routes: {
//         '/login': (context) => const auth.LoginScreen(),
//         '/dashboard': (context) => admin.AdminDashboardScreen(),
//       },
//     );
//   }
// }

