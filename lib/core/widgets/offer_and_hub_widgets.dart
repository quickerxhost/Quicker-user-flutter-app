import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../features/home/domain/models/banner_model.dart';
import '../../features/home/domain/models/delivery_hub_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Full-bleed rounded promo banner ("Limited Offer 🍔 Food Delivery",
/// "Festival Delights Flat 50% OFF"...).
class OfferBanner extends StatelessWidget {
  const OfferBanner({super.key, required this.banner, this.onTap});
  final BannerModel banner;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          gradient: const LinearGradient(
            colors: [AppColors.primaryContainer, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (banner.imageUrl.isNotEmpty)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.25,
                  child: CachedNetworkImage(imageUrl: banner.imageUrl, fit: BoxFit.cover),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    banner.title,
                    style: AppTypography.titleLg(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    banner.subtitle,
                    style: AppTypography.bodyMd(color: Colors.white.withValues(alpha: 0.9)),
                  ),
                  if (banner.code != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text('CODE: ${banner.code}', style: AppTypography.labelLg(color: Colors.white)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "CURRENT HUB" card shown at the top of Home, with ETA + shop count chips.
class DeliveryHubCard extends StatelessWidget {
  const DeliveryHubCard({super.key, required this.hub});
  final DeliveryHubModel hub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('CURRENT HUB', style: AppTypography.labelLg(color: AppColors.onPrimaryFixedVariant)),
            ],
          ),
          const SizedBox(height: 4),
          Text('📍 ${hub.name}', style: AppTypography.titleLg()),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _StatChip(icon: Icons.schedule, label: '${hub.etaMinutes} Minutes'),
              const SizedBox(width: 8),
              _StatChip(icon: Icons.storefront, label: '${hub.shopCount} Shops'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.onPrimaryFixedVariant),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.labelLg(color: AppColors.onPrimaryFixedVariant).copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

/// Premium Restaurant Banner — "Hungry? Order from Restaurant"
/// Features realistic food imagery, subtle steam effects, premium shadows,
/// and Quicker-X brand consistency.
class RestaurantBanner extends StatelessWidget {
  const RestaurantBanner({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F0F1A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 10),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Background food imagery layer
            Positioned.fill(
              child: Opacity(
                opacity: 0.15,
                child: CachedNetworkImage(
                  imageUrl:
                      'https://images.unsplash.com/photo-1565299507177-b0ac66763828?w=800&q=80',
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryFixed.withValues(alpha: 0.1),
                          AppColors.primaryFixed.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryFixed.withValues(alpha: 0.1),
                          AppColors.primaryFixed.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Subtle animated steam effect (constrained to banner bounds)
            const Positioned.fill(child: _SteamEffect()),
            // Food items illustration layer (bottom right)
            Positioned(
              right: -20,
              bottom: -30,
              child: Opacity(
                opacity: 0.25,
                child: CachedNetworkImage(
                  imageUrl:
                      'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=400&q=80',
                  fit: BoxFit.contain,
                  width: 220,
                  height: 220,
                  placeholder: (_, __) => const SizedBox(width: 220, height: 220),
                  errorWidget: (_, __, ___) => const SizedBox(width: 220, height: 220),
                ),
              ),
            ),
            // Delivery rider/bag silhouette (subtle)
            const Positioned(
              left: -10,
              bottom: -20,
              child: Opacity(
                opacity: 0.12,
                child: Icon(
                  Icons.two_wheeler_rounded,
                  size: 140,
                  color: Colors.white,
                ),
              ),
            ),
            // Content overlay
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md + 4,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fast Delivery badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.secondaryContainer.withValues(alpha: 0.9),
                          AppColors.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_shipping_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Fast Delivery',
                          style: AppTypography.labelLg(color: Colors.white).copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm + 4),
                  // Main heading
                  Text(
                    'Hungry? Order from Restaurant',
                    style: AppTypography.headlineLgMobile(color: Colors.white).copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -0.01 * 22,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Subheading
                  Text(
                    'Your favourite food, delivered fast.',
                    style: AppTypography.bodyMd(color: Colors.white.withValues(alpha: 0.85)).copyWith(
                      fontSize: 14,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // CTA Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryContainer, AppColors.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Order Now',
                              style: AppTypography.labelLg(color: Colors.white).copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Subtle animated steam particles for premium food delivery feel
class _SteamEffect extends StatefulWidget {
  const _SteamEffect();

  @override
  State<_SteamEffect> createState() => _SteamEffectState();
}

class _SteamEffectState extends State<_SteamEffect> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_SteamParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _particles = List.generate(6, (index) => _SteamParticle.random(index));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: _particles.map((particle) {
            final progress = (_controller.value + particle.delay) % 1.0;
            final y = particle.startY - progress * particle.distance;
            final opacity = (1.0 - progress) * particle.maxOpacity;
            final scale = 0.5 + progress * 0.5;

            return Positioned(
              left: particle.x,
              bottom: y,
              child: Opacity(
                opacity: opacity.clamp(0.0, 0.35),
                child: Transform.scale(
                  scale: scale,
child: Container(
                      width: particle.size,
                      height: particle.size,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SteamParticle {
  final double x;
  final double startY;
  final double distance;
  final double size;
  final double maxOpacity;
  final double delay;

  const _SteamParticle({
    required this.x,
    required this.startY,
    required this.distance,
    required this.size,
    required this.maxOpacity,
    required this.delay,
  });

  factory _SteamParticle.random(int index) {
    // Position steam particles across the top portion of the banner
    // Container is 200px tall, particles should stay within 0-200 from bottom
    final positions = [0.15, 0.35, 0.55, 0.75, 0.25, 0.65];
    return _SteamParticle(
      x: positions[index % positions.length] * 350,
      startY: 180.0 + (index * 5.0), // Start near top of banner (within 200px)
      distance: 80.0 + (index * 10.0), // Move up by max 130px, staying within bounds
      size: 4.0 + (index % 3) * 2.0,
      maxOpacity: 0.25 + (index % 2) * 0.1,
      delay: index * 0.15,
    );
  }
}
