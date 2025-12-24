import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/image_saver.dart';
import '../../logic/providers.dart';
import '../painters/heptapod_painter.dart';

class MaterializeTab extends ConsumerStatefulWidget {
  const MaterializeTab({super.key});

  @override
  ConsumerState<MaterializeTab> createState() => _MaterializeTabState();
}

class _MaterializeTabState extends ConsumerState<MaterializeTab> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(heptapodProvider);
    final notifier = ref.read(heptapodProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Input Section
          TextField(
            controller: _controller,
            style: AppTheme.zenMode.textTheme.bodyLarge,
            cursorColor: AppTheme.accent,
            decoration: InputDecoration(
              hintText: 'Enter a concept...',
              hintStyle: TextStyle(color: AppTheme.accent.withOpacity(0.3)),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.accent.withOpacity(0.3)),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.accent),
              ),
            ),
            onSubmitted: (value) => notifier.materialize(value),
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: state.isProcessing
              ? null
              : () => notifier.materialize(_controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent.withOpacity(0.1),
              foregroundColor: AppTheme.accent,
            ),
            child: state.isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent)
                )
              : const Text('MATERIALIZE'),
          ),

          const SizedBox(height: 40),

          // Visualization Section
          Expanded(
            child: Center(
              child: state.generatedSpectrum == null
                ? Text(
                    'Empty space awaits ink.',
                    style: TextStyle(color: AppTheme.accent.withOpacity(0.3)),
                  )
                : TweenAnimationBuilder<double>(
                    duration: const Duration(seconds: 3),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return CustomPaint(
                              size: Size(constraints.maxWidth, constraints.maxHeight),
                              painter: HeptapodPainter(
                                spectrum: state.generatedSpectrum!,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
            ),
          ),

          const SizedBox(height: 20),

          // Save Button
          if (state.generatedSpectrum != null)
            TextButton.icon(
              onPressed: () async {
                 await ImageSaver.saveHighQualityImage(state.generatedSpectrum!);
                 if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Saving high-res logogram...')),
                   );
                 }
              },
              icon: const Icon(Icons.save_alt, color: AppTheme.accent),
              label: const Text('Export High-Res', style: TextStyle(color: AppTheme.accent)),
            ),

          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                'Error: ${state.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
        ],
      ),
    );
  }
}
