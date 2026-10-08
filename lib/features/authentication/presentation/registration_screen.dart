import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../application/auth_controller.dart';

/// No Stitch design exists for this screen — built to match the app's
/// design system per the PRD's "Registration Screen" spec (Full Name,
/// Email, Profile Image, Language, Finish).
///
/// Profile-image upload is UI-only for now: it stores a local avatar
/// placeholder image picker hook (no image_picker dependency was requested
/// in the tech stack) — wire in your preferred picker when ready.
class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _language = 'English';

  static const _languages = ['English', 'हिन्दी', 'मराठी', 'தமிழ்', 'తెలుగు'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).register(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          language: _language,
        );
    final state = ref.read(authControllerProvider);
    if (state.status == AuthStatus.success && mounted) {
      context.go(RoutePaths.notificationPermission);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isSaving = authState.status == AuthStatus.verifying;

    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    const CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.surfaceContainerLow,
                      child: Icon(Icons.person_outline_rounded, size: 44, color: AppColors.outline),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Full Name', style: AppTypography.labelLg()),
              const SizedBox(height: 8),
              AppTextField(
                controller: _nameController,
                hintText: 'Enter your full name',
                prefixIcon: Icons.person_outline_rounded,
                validator: Validators.fullName,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Email (optional)', style: AppTypography.labelLg()),
              const SizedBox(height: 8),
              AppTextField(
                controller: _emailController,
                hintText: 'you@example.com',
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Preferred Language', style: AppTypography.labelLg()),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _languages.map((lang) {
                  final selected = _language == lang;
                  return ChoiceChip(
                    label: Text(lang),
                    selected: selected,
                    onSelected: (_) => setState(() => _language = lang),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xxl),
              PrimaryButton(label: 'Finish', trailingIcon: null, isLoading: isSaving, onPressed: _finish),
            ],
          ),
        ),
      ),
    );
  }
}
