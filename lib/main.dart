import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';

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
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Heptapod Protocol'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Text(
          'Zen Mode',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
