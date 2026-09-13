import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_common_widgets.dart';
import '../providers/driver_provider.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverProvider>().attachSocketListeners();
    });
  }

  void _showOfferSheet(BuildContext context, IncomingRequest request) {
    final priceController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            top: AppSpacing.xl,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('إرسال عرض سعر', style: AppTextStyles.headline(colors.textPrimary)),
              const SizedBox(height: AppSpacing.md),
              Text(
                'نوع المركبة: ${AppConfig.vehicleCategories[request.vehicleType] ?? request.vehicleType}',
                style: AppTextStyles.bodyMedium(colors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: AppTextStyles.bodyLarge(colors.textPrimary),
                decoration: InputDecoration(labelText: 'السعر (${AppConfig.currency})'),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'إرسال العرض',
                icon: Icons.send_rounded,
                onPressed: () {
                  final price = double.tryParse(priceController.text.trim());
                  if (price == null || price <= 0) return;
                  context.read<DriverProvider>().sendOffer(request.requestId, price);
                  Navigator.pop(sheetContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final driverProv = context.watch<DriverProvider>();
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('لوحة السائق')),
      body: Column(
        children: [
          if (driverProv.hasActiveTrip)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(AppSpacing.lg),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('لديك رحلة نشطة حالياً', style: AppTextStyles.title(Colors.white)),
                  const SizedBox(height: AppSpacing.sm),
                  Text('اضغط أدناه فور تسليم المركبة للعميل', style: AppTextStyles.bodyMedium(Colors.white.withValues(alpha: 0.9))),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'إنهاء الرحلة',
                    icon: Icons.flag_circle_rounded,
                    variant: AppButtonVariant.ghost,
                    onPressed: () => context.read<DriverProvider>().completeActiveTrip(),
                  ),
                ],
              ),
            ).animate().fadeIn(),

          Expanded(
            child: driverProv.incomingRequests.isEmpty
                ? const AppEmptyState(
                    icon: Icons.local_shipping_outlined,
                    title: 'لا توجد طلبات قادمة حالياً',
                    subtitle: 'ستظهر هنا الطلبات القريبة منك فور وصولها',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: driverProv.incomingRequests.length,
                    itemBuilder: (context, index) {
                      final request = driverProv.incomingRequests[index];
                      return _RequestCard(
                        request: request,
                        onOffer: () => _showOfferSheet(context, request),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final IncomingRequest request;
  final VoidCallback onOffer;

  const _RequestCard({required this.request, required this.onOffer});

  @override
  Widget build(BuildContext context) {

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car_rounded, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                AppConfig.vehicleCategories[request.vehicleType] ?? request.vehicleType,
                style: AppTextStyles.title(colors.textPrimary),
              ),
              const Spacer(),
              Text('${request.price.round()} ${AppConfig.currency}', style: AppTextStyles.title(AppColors.primary)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 18, color: colors.textSecondary),
              const SizedBox(width: 4),
              Text('موقع الانطلاق محدد على الخريطة', style: AppTextStyles.bodySmall(colors.textSecondary)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(label: 'إرسال عرض سعر', icon: Icons.attach_money_rounded, onPressed: onOffer),
        ],
      ),
    ).animate().slideY(begin: 0.2, duration: AppDurations.normal);
  }
}
