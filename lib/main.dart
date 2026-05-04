import 'package:flutter/material.dart';
import 'package:stockmind/app.dart';
import 'package:stockmind/core/theme/theme_provider.dart';
import 'package:stockmind/services/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrap = await FirebaseBootstrap.initialize();
  final themeProvider = ThemeProvider();
  await themeProvider.load();
  runApp(
    StockMindApp(
      bootstrap: bootstrap,
      themeProvider: themeProvider,
    ),
  );
}
