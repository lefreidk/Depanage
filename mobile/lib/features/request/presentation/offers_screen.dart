import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/request_provider.dart';
import '../../tracking/presentation/tracking_screen.dart';
import 'offer_card.dart';

class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requestProv = context.watch<RequestProvider>();
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('عروض السائقين'),
        actions: [
          if (requestProv.offers.isEmpty)
            TextButton(
              onPressed: () {
                context.read<RequestProvider>().reset();
                Navigator.pop(context);
              },
              child: const Text('إلغاء'),
            ),
        ],
      ),
      body: requestProv.offers.isEmpty
          ? _WaitingState(colors: colors)
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: requestProv.offers.length,
              itemBuilder: (context, index) {
                final offer = requestProv.offers[index];
                return OfferCard(
                  offer: offer,
                  onAccept: () {
                    context.read<RequestProvider>().acceptOffer(offer);
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TrackingScreen()));
                  },
                );
              },
            ),
    );
  }
}

class _WaitingState extends StatelessWidget {
  final AppSemanticColors colors;
  const _WaitingState({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(color: colors.surfaceAlt, shape: BoxShape.circle),
                  child: const Icon(Icons.radar_rounded, color: AppColors.primary, size: 38),
                ).animate(onPlay: (c) => c.repeat()).rotate(duration: 3.seconds),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('جاري البحث عن سائقين قريبين...', style: AppTextStyles.title(colors.textPrimary)),
          const SizedBox(height: AppSpacing.xs),
          Text('سيصلك إشعار فور وصول أول عرض', style: AppTextStyles.bodyMedium(colors.textSecondary)),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
