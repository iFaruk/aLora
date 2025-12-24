import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'ui/screens/home_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: HeptapodProtocolApp(),
    ),
  );
}

class HeptapodProtocolApp extends StatelessWidget {
  const HeptapodProtocolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Heptapod Protocol',
      theme: AppTheme.zenMode,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
