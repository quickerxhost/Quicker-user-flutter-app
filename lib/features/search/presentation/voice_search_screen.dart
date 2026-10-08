import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../application/search_controller.dart';

/// Matches Stitch `voice_search_interface`: full-screen mic pulse
/// animation, live transcript, "Listening..." status, tap-to-stop.
class VoiceSearchScreen extends ConsumerStatefulWidget {
  const VoiceSearchScreen({super.key});

  @override
  ConsumerState<VoiceSearchScreen> createState() => _VoiceSearchScreenState();
}

class _VoiceSearchScreenState extends ConsumerState<VoiceSearchScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _available = false;
  String _transcript = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) => setState(() => _isListening = false),
    );
    if (_available) _startListening();
    setState(() {});
  }

  void _startListening() {
    setState(() => _isListening = true);
    _speech.listen(
      onResult: (result) => setState(() => _transcript = result.recognizedWords),
    );
  }

  void _stopAndSearch() {
    _speech.stop();
    setState(() => _isListening = false);
    if (_transcript.trim().isNotEmpty) {
      ref.read(searchQueryControllerProvider.notifier).search(_transcript.trim());
      context.pop();
      context.push(RoutePaths.search);
    }
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
              const Spacer(),
              _MicPulse(isListening: _isListening, onTap: _isListening ? _stopAndSearch : _startListening),
              const SizedBox(height: AppSpacing.xl),
              Text(
                _isListening ? 'Listening...' : (_available ? 'Tap to speak' : 'Speech recognition unavailable'),
                style: AppTypography.titleLg(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _transcript.isEmpty ? 'Try "Fresh vegetables near me"' : _transcript,
                style: AppTypography.bodyLg(color: Colors.white.withValues(alpha: 0.9)),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _MicPulse extends StatefulWidget {
  const _MicPulse({required this.isListening, required this.onTap});
  final bool isListening;
  final VoidCallback onTap;

  @override
  State<_MicPulse> createState() => _MicPulseState();
}

class _MicPulseState extends State<_MicPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = widget.isListening ? 1 + (_controller.value * 0.25) : 1.0;
          return Stack(
            alignment: Alignment.center,
            children: [
              if (widget.isListening)
                Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                  ),
                ),
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.mic_rounded, size: 52, color: AppColors.primary),
              ),
            ],
          );
        },
      ),
    );
  }
}
