import 'package:flutter/material.dart';
import 'features/lsa_verification/screens/lsa_verification_screen.dart';

void main() {
  runApp(const HabotConnectApp());
}

/// Root application widget.
///
/// Material 3 with a deep-teal seed to convey trust and compliance authority —
/// deliberately distinct from generic blue/purple to reflect the premium, detail-
/// obsessed culture described in HabotConnect's Values document.
class HabotConnectApp extends StatelessWidget {
  const HabotConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HabotConnect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006D5B), // deep teal — trust, compliance
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006D5B),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      ),
      themeMode: ThemeMode.system,
      home: const LsaVerificationScreen(),
    );
  }
}
