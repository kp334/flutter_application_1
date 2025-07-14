import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_page.dart';
import 'theme_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

// ✅ Tambahan: Custom dark theme yang tidak terlalu gelap
final ThemeData customDarkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF2C2C3E),
  primaryColor: Colors.teal.shade200,
  cardColor: const Color(0xFF3A3A4F),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF3A3A4F),
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Colors.white70),
    bodySmall: TextStyle(color: Colors.white60),
  ),
  popupMenuTheme: const PopupMenuThemeData(color: Color(0xFF4A4A5F)),
  dividerColor: Colors.white24,
  useMaterial3: true,
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aplikasi Scada',
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      darkTheme: customDarkTheme, // 🔁 Pakai dark theme yang sudah disesuaikan
      home: const LoginPage(),
    );
  }
}
