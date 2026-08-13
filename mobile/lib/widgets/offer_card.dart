import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/offer.dart';
import '../theme.dart';
import '../config.dart';
import '../localizations/app_localizations.dart';

class OfferCard extends StatelessWidget {
  final Offer offer;
  final VoidCallback onAccept;

  const OfferCard({
    Key? key,
    required this.offer,
    required this.onAccept,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? AppTheme.darkSurface : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة السائق واسمه وتقييمه
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  backgroundImage: offer.driverPhotoUrl != null
                      ? NetworkImage(offer.driverPhotoUrl!)
                      : null,
                  child: offer.driverPhotoUrl == null
                      ? Icon(Icons.person, color: AppTheme.primary, size: 30)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.providerName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (offer.rating != null) ...[
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              offer.rating!.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          const Icon(Icons.verified, color: Colors.green, size: 16),
                        ],
                      ),
                    ],
                  ),
                ),
                // السعر
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${offer.price.round()} ${AppConfig.currency}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    if (offer.distanceKm != null)
                      Text(
                        '${offer.distanceKm!.toStringAsFixed(1)} كم',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey.shade300),
            const SizedBox(height: 12),

            // نوع السطحة واللوحة والوقت
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (offer.truckType != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.local_shipping,
                          color: AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        offer.truckType!,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                      if (offer.truckPlate != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          offer.truckPlate!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ] else
                  Text(
                    lang.translate('not_specified') ?? 'غير محدد',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                if (offer.etaMinutes != null)
                  Row(
                    children: [
                      const Icon(Icons.timer, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${offer.etaMinutes} ${lang.translate('minutes') ?? 'دقائق'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // زر قبول العرض
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAccept,
                icon: const Icon(Icons.check_circle),
                label: Text(lang.translate('accept_offer') ?? 'قبول العرض'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 0.3, duration: 400.ms, curve: Curves.easeOut);
  }
}
