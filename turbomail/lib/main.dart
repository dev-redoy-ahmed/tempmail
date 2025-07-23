import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/email_provider.dart';
import 'providers/premium_provider.dart';
import 'services/ads_service.dart';
import 'services/app_update_service.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Ads Service
  await AdsService().initialize();
  
  // Create EmailProvider instance
  final emailProvider = EmailProvider();
  
  // Auto-generate an email when the app starts
  await emailProvider.generateRandomEmail();
  
  // Show app open ad after initialization
  await AdsService().showAppOpenAd();
  
  runApp(TurboMailApp(emailProvider: emailProvider));
}

class TurboMailApp extends StatefulWidget {
  final EmailProvider emailProvider;
  
  const TurboMailApp({super.key, required this.emailProvider});

  @override
  State<TurboMailApp> createState() => _TurboMailAppState();
}

class _TurboMailAppState extends State<TurboMailApp> {
  @override
  void initState() {
    super.initState();
    // Initialize app update service after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppUpdateService.initialize(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.emailProvider),
        ChangeNotifierProvider(create: (_) => PremiumProvider()),
      ],
      child: MaterialApp(
        title: 'TurboMail',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF1A2434),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00D4AA),
            secondary: Color(0xFF1DB584),
            surface: Color(0xFF1A2434),
            background: Color(0xFF1A2434),
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: Colors.white,
            onBackground: Colors.white,
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF1A2434),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4AA),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF1A2434),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00D4AA)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00D4AA), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00D4AA), width: 2),
            ),
            labelStyle: const TextStyle(color: Colors.white70),
            hintStyle: const TextStyle(color: Colors.white54),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1A2434),
            elevation: 0,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF1A2434),
            selectedItemColor: Color(0xFF00D4AA),
            unselectedItemColor: Colors.white54,
            type: BottomNavigationBarType.fixed,
          ),
        ),
        home: const DashboardScreen(),
      ),
    );
  }
}
