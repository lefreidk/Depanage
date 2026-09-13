import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/request_provider.dart';
import 'offers_screen.dart';

class RequestDetailScreen extends StatefulWidget {
  final String vehicleCategory;
  final LatLng pickupLocation;

  const RequestDetailScreen({
    super.key,
    required this.vehicleCategory,
    required this.pickupLocation,
  });

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  LatLng? _dropoff;
  double _distanceKm = 0;
  double _price = 0;
  bool _isSearching = false;
  final _searchController = TextEditingController();

  double _calcDistance(LatLng a, LatLng b) => const Distance().as(LengthUnit.Kilometer, a, b);

  double _calcSuggestedPrice(double km) {
    final perKm = AppConfig.pricePerKm[widget.vehicleCategory] ?? 500;
    return (km * perKm).roundToDouble();
  }

  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);
    try {
      final uri = Uri.parse('https://nominatim.openstreetmap.org/search?format=json&limit=1&q=$query');
      final res = await http.get(uri, headers: {'User-Agent': 'depannage-app'});
      final results = jsonDecode(res.body) as List;

      if (results.isNotEmpty) {
        final point = LatLng(double.parse(results[0]['lat']), double.parse(results[0]['lon']));
        _setDropoff(point);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لم يتم العثور على العنوان')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر البحث، جرّب النقر على الخريطة')));
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _setDropoff(LatLng point) {
    setState(() {
      _dropoff = point;
      _distanceKm = _calcDistance(widget.pickupLocation, point);
      _price = _calcSuggestedPrice(_distanceKm);
    });
  }

  void _adjustPrice(double delta) {
    setState(() => _price = (_price + delta).clamp(0, 100000));
  }

  void _publish() {
    if (_dropoff == null) return;

    context.read<RequestProvider>().publishRequest(
          vehicleType: widget.vehicleCategory,
          pickupLat: widget.pickupLocation.latitude,
          pickupLng: widget.pickupLocation.longitude,
          dropoffLat: _dropoff!.latitude,
          dropoffLng: _dropoff!.longitude,
          price: _price,
        );

    Navigator.push(context, MaterialPageRoute(builder: (_) => const OffersScreen()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final requestProv = context.watch<RequestProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الطلب')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: widget.pickupLocation,
              initialZoom: 13,
              onTap: (_, point) => _setDropoff(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.depannage.app',
              ),
              MarkerLayer(markers: [
                Marker(
                  point: widget.pickupLocation,
                  width: 54,
                  height: 54,
                  child: const Icon(Icons.car_repair_rounded, color: AppColors.primary, size: 40),
                ),
                if (_dropoff != null)
                  Marker(
                    point: _dropoff!,
                    width: 46,
                    height: 46,
                    child: const Icon(Icons.flag_rounded, color: AppColors.success, size: 36),
                  ),
              ]),
            ],
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.sm,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 4),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12)],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: AppTextStyles.bodyLarge(colors.textPrimary),
                      onSubmitted: (_) => _searchAddress(),
                      decoration: const InputDecoration(
                        hintText: 'ابحث عن عنوان الوجهة...',
                        border: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isSearching ? null : _searchAddress,
                    icon: _isSearching
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.search_rounded, color: AppColors.primary),
                  ),
                ],
              ),
            ),
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
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 18)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.route_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _dropoff == null
                            ? 'ابحث أو اضغط على الخريطة لتحديد الوجهة'
                            : 'المسافة: ${_distanceKm.toStringAsFixed(1)} كم',
                        style: AppTextStyles.bodyMedium(colors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppCircleIconButton(
                        icon: Icons.remove_rounded,
                        onTap: _dropoff == null ? () {} : () => _adjustPrice(-100),
                      ),
                      Column(
                        children: [
                          Text('السعر المقترح', style: AppTextStyles.bodySmall(colors.textSecondary)),
                          Text(
                            '${_price.round()} ${AppConfig.currency}',
                            style: AppTextStyles.numericLarge(AppColors.primary),
                          ),
                        ],
                      ),
                      AppCircleIconButton(
                        icon: Icons.add_rounded,
                        onTap: _dropoff == null ? () {} : () => _adjustPrice(100),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: requestProv.isPublishing ? 'جاري النشر...' : 'نشر الطلب للسائقين القريبين',
                    icon: Icons.campaign_rounded,
                    variant: AppButtonVariant.secondary,
                    isLoading: requestProv.isPublishing,
                    onPressed: _dropoff == null ? null : _publish,
                  ),
                ],
              ),
            ).animate().slideY(begin: 1, duration: AppDurations.slow, curve: Curves.easeOutCubic),
          ),
        ],
      ),
    );
  }
}
