import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/location_provider.dart';
import '../../request/presentation/request_detail_screen.dart';

import '../../request/providers/request_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'car';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().getCurrentLocation();
      context.read<RequestProvider>().attachSocketListeners();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'motorcycle':
        return Icons.two_wheeler_rounded;
      case 'utility':
        return Icons.airport_shuttle_rounded;
      case 'truck':
        return Icons.local_shipping_outlined;
      case 'heavy_truck':
        return Icons.fire_truck_rounded;
      default:
        return Icons.directions_car_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationProv = context.watch<LocationProvider>();
    final colors = context.colors;

    return Scaffold(
      drawer: const AppDrawer(),
      body: locationProv.currentPosition == null
          ? _buildLoadingState(colors)
          : Stack(
              children: [
                _buildMap(locationProv.currentPosition!),
                _buildTopBar(context, colors),
                _buildVehicleSelector(colors),
                _buildBottomSearchCard(colors),
              ],
            ),
    );
  }

  Widget _buildLoadingState(AppSemanticColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.lg),
          Text(context.watch<LocationProvider>().status, style: AppTextStyles.bodyMedium(colors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildMap(LatLng position) {
    return FlutterMap(
      options: MapOptions(initialCenter: position, initialZoom: AppConfig.defaultZoom),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.depannage.app',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: position,
              width: 64,
              height: 64,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 14)],
                ),
                child: const Icon(Icons.car_repair_rounded, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context, AppSemanticColors colors) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + AppSpacing.sm,
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppCircleIconButton(
            icon: Icons.menu_rounded,
            backgroundColor: colors.surface,
            onTap: () => Scaffold.of(context).openDrawer(),
          ),
          AppCircleIconButton(
            icon: Icons.notifications_none_rounded,
            backgroundColor: colors.surface,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSelector(AppSemanticColors colors) {
    return Positioned(
      top: 76,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 76,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          scrollDirection: Axis.horizontal,
          itemCount: AppConfig.vehicleCategories.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, index) {
            final key = AppConfig.vehicleCategories.keys.elementAt(index);
            final label = AppConfig.vehicleCategories[key]!;
            final isSelected = _selectedCategory == key;

            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = key),
              child: AnimatedContainer(
                duration: AppDurations.fast,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : colors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isSelected ? 0.15 : 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(_iconFor(key), size: 22, color: isSelected ? Colors.white : AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      label,
                      style: AppTextStyles.bodyMedium(isSelected ? Colors.white : colors.textPrimary),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ).animate().slideY(begin: -0.3, duration: AppDurations.normal);
  }

  Widget _buildBottomSearchCard(AppSemanticColors colors) {
    return Positioned(
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      bottom: AppSpacing.xl,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.search_rounded, color: colors.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: AppTextStyles.bodyLarge(colors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'ما الوجهة وما التكلفة؟',
                      border: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      hintStyle: AppTextStyles.bodyMedium(colors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'طلب سطحة الآن',
              icon: Icons.local_shipping_rounded,
              onPressed: () {
                final position = context.read<LocationProvider>().currentPosition;
                if (position == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RequestDetailScreen(
                      vehicleCategory: _selectedCategory,
                      pickupLocation: position,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 1, duration: AppDurations.slow, curve: Curves.easeOutCubic);
  }
}
