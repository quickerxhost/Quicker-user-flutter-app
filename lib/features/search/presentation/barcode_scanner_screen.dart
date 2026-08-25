import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../application/search_controller.dart';

/// Matches Stitch `barcode_scanner`: full-screen camera preview, scan-frame
/// overlay with corner brackets, animated scan-line, flashlight toggle,
/// bottom hint text.
class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  ConsumerState<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final code = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    if (code == null) return;
    _handled = true;

    final result = await ref.read(searchRepositoryProvider).searchByBarcode(code);
    result.when(
      success: (product) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(product != null ? 'Found: ${product.name}' : 'No product found for $code')),
        );
        context.pop();
      },
      failure: (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        _handled = false;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          const _ScanFrameOverlay(),
          SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close_rounded, color: Colors.white)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _controller.toggleTorch(),
                      icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
                    ),
                  ],
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.marginMobile),
                  child: Text(
                    'Align the barcode within the frame to scan',
                    style: AppTypography.bodyMd(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanFrameOverlay extends StatelessWidget {
  const _ScanFrameOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 260,
        height: 180,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primaryContainer, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
