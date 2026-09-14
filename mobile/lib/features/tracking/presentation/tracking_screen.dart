import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app_config.dart';
import '../../../core/network/socket_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../request/providers/request_provider.dart';
import '../../rating/presentation/completion_rating_screen.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  LatLng? _truckPosition;

  @override
  void initState() {
    super.initState();
    final socket = SocketClient.instance.socket;

    socket.off('provider:location:update');
    socket.on('provider:location:update', (data) {
      if (!mounted) return;
      if (data is Map && data['lat'] != null && data['lng'] != null) {
        setState(() => _truckPosition = LatLng((data['lat'] as num).toDouble(), (data['lng'] as num).toDouble()));
      }
    });

    socket.off('trip:completed');
    socket.on('trip:completed', (_) {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CompletionRatingScreen()));
    });
  }

  Future<void> _callDriver(String phone) async {
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رقم السائق غير متوفر حالياً')));
      return;
    }
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<RequestProvider>().currentRequest;
    final colors = context.colors;

    if (request == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تتبع السطحة')),
        body: const Center(child: Text('لا يوجد طلب نشط')),
      );
    }

    final pickup = LatLng(request.pickupLat, request.pickupLng);
    final dropoff = LatLng(request.dropoffLat, request.dropoffLng);

    return Scaffold(
      appBar: AppBar(title: const Text('تتبع السطحة')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(initialCenter: _truckPosition ?? pickup, initialZoom: 13),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.depannage.app',
              ),
              MarkerLayer(markers: [
                Marker(point: pickup, width: 46, height: 46, child: const Icon(Icons.car_repair, color: AppColors.primary, size: 36)),
                Marker(point: dropoff, width: 46, height: 46, child: const Icon(Icons.flag_rounded, color: AppColors.success, size: 36)),
                if (_truckPosition != null)
                  Marker(
                    point: _truckPosition!,
                    width: 58,
                    height: 58,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.4), blurRadius: 12)],
                      ),
                      child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 26),
                    ),
                  ),
              ]),
            ],
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 18)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: const Icon(Icons.person_rounded, color: AppColors.primary),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(request.providerName ?? 'السائق في الطريق', style: AppTextStyles.title(colors.textPrimary)),
                            if (request.providerPlate != null)
                              Text('اللوحة: ${request.providerPlate}', style: AppTextStyles.bodySmall(colors.textSecondary)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _callDriver(''),
                        icon: const Icon(Icons.phone_rounded, color: AppColors.success, size: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.payments_rounded, color: AppColors.accent),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text('الدفع نقداً حصراً عند الوصول', style: AppTextStyles.bodyMedium(colors.textPrimary))),
                        Text('${request.price.round()} ${AppConfig.currency}', style: AppTextStyles.title(AppColors.primary)),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().slideY(begin: 1, duration: AppDurations.slow),
          ),
        ],
      ),
    );
  }
}
