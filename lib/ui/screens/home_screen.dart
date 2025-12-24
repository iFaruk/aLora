import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'materialize_tab.dart';
import 'interpret_tab.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          elevation: 0,
          title: Text(
            'HEPTAPOD PROTOCOL',
            style: AppTheme.zenMode.textTheme.titleLarge?.copyWith(
              letterSpacing: 4.0,
              fontSize: 16,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: AppTheme.accent,
            indicatorWeight: 1,
            labelColor: AppTheme.accent,
            unselectedLabelColor: AppTheme.accent.withOpacity(0.3),
            labelStyle: const TextStyle(letterSpacing: 2.0),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'MATERIALIZE'),
              Tab(text: 'INTERPRET'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            MaterializeTab(),
            InterpretTab(),
          ],
        ),
      ),
    );
  }
}
