import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../models/tow_request_model.dart';

class OfferCard extends StatelessWidget {
  final OfferModel offer;
  final VoidCallback onAccept;

  const OfferCard({super.key, required this.offer, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(offer.providerName, style: AppTextStyles.title(colors.textPrimary)),
                    if (offer.rating != null)
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.warning, size: 16),
                          const SizedBox(width: 2),
                          Text(offer.rating!.toStringAsFixed(1), style: AppTextStyles.bodySmall(colors.textSecondary)),
                        ],
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${offer.price.round()} ${AppConfig.currency}', style: AppTextStyles.title(AppColors.primary)),
                  if (offer.distanceKm != null)
                    Text('${offer.distanceKm!.toStringAsFixed(1)} كم', style: AppTextStyles.bodySmall(colors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(label: 'قبول العرض', icon: Icons.check_circle_rounded, onPressed: onAccept),
        ],
      ),
    ).animate().slideY(begin: 0.2, duration: AppDurations.normal);
  }
}
