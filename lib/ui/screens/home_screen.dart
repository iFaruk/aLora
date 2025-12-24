import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../logic/providers.dart';
import 'materialize_tab.dart';
import 'interpret_tab.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _showSettingsDialog(BuildContext context, WidgetRef ref) {
    final currentKey = ref.read(geminiApiKeyProvider);
    final controller = TextEditingController(text: currentKey);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.background,
          title: Text('Configuration', style: AppTheme.zenMode.textTheme.titleLarge),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your Gemini API Key:',
                style: TextStyle(color: AppTheme.accent.withOpacity(0.7)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                style: AppTheme.zenMode.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'API Key',
                  hintStyle: TextStyle(color: AppTheme.accent.withOpacity(0.3)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.accent.withOpacity(0.3)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.accent),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: AppTheme.accent.withOpacity(0.5))),
            ),
            TextButton(
              onPressed: () {
                ref.read(geminiApiKeyProvider.notifier).state = controller.text;
                Navigator.pop(context);
              },
              child: const Text('Save', style: TextStyle(color: AppTheme.accent)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          actions: [
            IconButton(
              icon: Icon(Icons.settings, color: AppTheme.accent.withOpacity(0.3)),
              onPressed: () => _showSettingsDialog(context, ref),
            ),
          ],
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
