import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../logic/providers.dart';

class InterpretTab extends ConsumerStatefulWidget {
  const InterpretTab({super.key});

  @override
  ConsumerState<InterpretTab> createState() => _InterpretTabState();
}

class _InterpretTabState extends ConsumerState<InterpretTab> with SingleTickerProviderStateMixin {
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      ref.read(heptapodProvider.notifier).interpret(File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(heptapodProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Image Selection Area
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black12,
                ),
                child: state.selectedImage == null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                              size: 48, color: AppTheme.accent.withOpacity(0.5)),
                            const SizedBox(height: 10),
                            Text('Tap to select logogram',
                                style: TextStyle(color: AppTheme.accent.withOpacity(0.5))),
                          ],
                        ),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            state.selectedImage!,
                            fit: BoxFit.contain,
                          ),
                          if (state.isProcessing)
                            AnimatedBuilder(
                              animation: _scanController,
                              builder: (context, child) {
                                return FractionallySizedBox(
                                  heightFactor: 0.1,
                                  alignment: Alignment(0, -1.0 + 2.0 * _scanController.value),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          AppTheme.accent.withOpacity(0.0),
                                          AppTheme.accent.withOpacity(0.5),
                                          AppTheme.accent.withOpacity(0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Interpretation Result
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              child: Column(
                children: [
                   if (state.isProcessing)
                     const Text('Analyzing density and frequency...',
                        style: TextStyle(fontStyle: FontStyle.italic)),

                   if (state.interpretation != null)
                     TweenAnimationBuilder<double>(
                       key: ValueKey(state.interpretation),
                       duration: const Duration(milliseconds: 800),
                       tween: Tween(begin: 0.0, end: 1.0),
                       builder: (context, value, child) {
                         return Opacity(
                           opacity: value,
                           child: Text(
                             state.interpretation!,
                             style: AppTheme.zenMode.textTheme.bodyLarge?.copyWith(height: 1.6),
                             textAlign: TextAlign.center,
                           ),
                         );
                       },
                     ),

                   if (state.error != null)
                     Text('Error: ${state.error}', style: const TextStyle(color: Colors.redAccent)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
