import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../../location/presentation/location_permission_dialog.dart';
import '../domain/onboarding_page_model.dart';

/// Matches Stitch `onboarding_get_started` (page 1: hero + category chip
/// row + "Get Started") and `onboarding_shop_local` (page 2: "Skip" +
/// benefit chips + "Shop Local" + "Next").
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  static bool _locationPromptShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_locationPromptShown) {
        _locationPromptShown = true;
        showFetchLocationDialog(context);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finish() => context.go(RoutePaths.login);

  @override
  Widget build(BuildContext context) {
    final isLastPage = _page == kOnboardingPages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile, vertical: AppSpacing.sm),
                child: TextButton(
                  onPressed: _finish,
                  child: Text('Skip', style: AppTypography.labelLg(color: AppColors.onSurfaceVariant)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: kOnboardingPages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) => _OnboardingPage(page: kOnboardingPages[index]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                kOnboardingPages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _page ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _page ? AppColors.primary : AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.marginMobile),
              child: PrimaryButton(
                label: isLastPage ? 'Shop Local' : 'Get Started',
                onPressed: () {
                  if (isLastPage) {
                    _finish();
                  } else {
                    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.page});
  final OnboardingPageModel page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: const BoxDecoration(color: AppColors.primaryFixed, shape: BoxShape.circle),
            child: Icon(page.heroIcon, size: 64, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(page.title, style: AppTypography.headlineLgMobile(), textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(
            page.description,
            style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: List.generate(page.chipIcons.length, (i) {
              return Chip(
                avatar: Icon(page.chipIcons[i], size: 16, color: AppColors.primary),
                label: Text(page.chipLabels[i]),
                backgroundColor: AppColors.surfaceContainerLow,
                side: BorderSide.none,
              );
            }),
          ),
        ],
      ),
    );
  }
}
