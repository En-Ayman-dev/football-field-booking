// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/database/database_helper.dart';
import 'features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'providers/auth_provider.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbHelper = DatabaseHelper();
  await dbHelper.seedAdminUser();

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

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  ThemeData get _lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.green,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
      ),
    );
  }

  ThemeData get _darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.green,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ArenaManager',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: _themeMode,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: AdminDashboardScreenWrapper(
            isDarkMode: _themeMode == ThemeMode.dark,
            onToggleTheme: _toggleTheme,
          ),
        ),
      ),
    );
  }
}

class AdminDashboardScreenWrapper extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const AdminDashboardScreenWrapper({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الملاعب - ArenaManager'),
        actions: [
          IconButton(
            onPressed: onToggleTheme,
            tooltip: isDarkMode ? 'الوضع الفاتح' : 'الوضع الداكن',
            icon: Icon(
              isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
          ),
        ],
      ),
      body: const AdminDashboardScreen(),
    );
  }
}
