import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:local_auth/local_auth.dart';

import 'home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MasareefiApp());
}

class MasareefiApp extends StatefulWidget {
  const MasareefiApp({super.key});

  @override
  State<MasareefiApp> createState() => _MasareefiAppState();
}

class _MasareefiAppState extends State<MasareefiApp> {
  ThemeMode _themeMode = ThemeMode.system;

  // تم تصليح الخلل: بدل ما نرجع نسخة وهمية جديدة من الحالة،
  // نمرر هذا الكولباك مباشرة للشاشات اللي تحتاج تغيّر الثيم
  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مصاريفي',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: _themeMode,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal, brightness: Brightness.light),
      darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal, brightness: Brightness.dark),
      home: AuthGate(onToggleTheme: toggleTheme),
    );
  }
}

class AuthGate extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const AuthGate({super.key, required this.onToggleTheme});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _authenticated = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    try {
      bool authenticated = await auth.authenticate(
        localizedReason: 'الرجاء التبصيم لفتح تطبيق مصاريفي',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false),
      );
      setState(() { _authenticated = authenticated; });
    } catch (e) {
      setState(() { _authenticated = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_authenticated) return HomeScreen(onToggleTheme: widget.onToggleTheme);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.teal),
            const SizedBox(height: 20),
            const Text('تطبيق مصاريفي مغلق', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _authenticate,
              icon: const Icon(Icons.fingerprint),
              label: const Text('إلغاء القفل'),
            )
          ],
        ),
      ),
    );
  }
}
