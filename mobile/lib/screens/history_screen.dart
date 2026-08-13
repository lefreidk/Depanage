import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';

import '../providers/request_provider.dart';
import '../theme.dart';
import '../config.dart';
import '../localizations/app_localizations.dart';
import '../models/tow_request.dart';
import 'request_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  // فتح محادثة واتساب مع الدعم الفني
  Future<void> _openSupportWhatsApp(BuildContext context) async {
    final url = 'https://wa.me/${AppConfig.supportWhatsAppNumber}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر فتح واتساب')),
      );
    }
  }

  // إعادة طلب رحلة مشابهة
  void _reorder(BuildContext context, TowRequest request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RequestDetailScreen(
          vehicleCategory: request.vehicleType,
          pickupLocation: LatLng(request.pickupLat, request.pickupLng),
        ),
      ),
    );
  }

  // فتح تفاصيل الرحلة
  void _showTripDetails(BuildContext context, TowRequest request) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 24),

              Text(
                lang.translate('trip_details') ?? 'تفاصيل الرحلة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 16),

              _buildInfoRow(
                icon: Icons.car_repair,
                label: lang.translate('pickup') ?? 'الانطلاق',
                value: lang.translate('pickup_location') ?? 'موقع العطل',
                isDark: isDark,
              ),
              SizedBox(height: 8),
              _buildInfoRow(
                icon: Icons.flag,
                label: lang.translate('dropoff') ?? 'الوصول',
                value: lang.translate('dropoff_location') ?? 'الوجهة النهائية',
                isDark: isDark,
              ),
              Divider(height: 24, color: Colors.grey.shade300),
              _buildInfoRow(
                icon: Icons.person,
                label: lang.translate('driver') ?? 'السائق',
                value: request.providerName ?? lang.translate('not_specified') ?? 'غير محدد',
                isDark: isDark,
              ),
              SizedBox(height: 8),
              _buildInfoRow(
                icon: Icons.local_shipping,
                label: lang.translate('plate_number') ?? 'اللوحة',
                value: request.providerPlate ?? lang.translate('not_specified') ?? 'غير محدد',
                isDark: isDark,
              ),
              SizedBox(height: 8),
              _buildInfoRow(
                icon: Icons.payments,
                label: lang.translate('cost') ?? 'التكلفة',
                value: '${request.price.round()} ${AppConfig.currency}',
                isDark: isDark,
              ),
              SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _reorder(context, request);
                  },
                  icon: Icon(Icons.replay),
                  label: Text(lang.translate('reorder') ?? 'إعادة الطلب'),
                ),
              ),
              SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _openSupportWhatsApp(context);
                  },
                  icon: Icon(Icons.support_agent, color: Colors.green),
                  label: Text(lang.translate('call_support') ?? 'الاتصال بالدعم الفني'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        SizedBox(width: 12),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getVehicleIcon(String category) {
    switch (category) {
      case 'motorcycle':
        return Icons.two_wheeler;
      case 'car':
        return Icons.directions_car;
      case 'utility':
        return Icons.car_rental;
      case 'truck':
        return Icons.local_shipping;
      case 'heavy_truck':
        return Icons.fire_truck;
      default:
        return Icons.directions_car;
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestProv = context.watch<RequestProvider>();
    final history = requestProv.history;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('history') ?? 'سجل الطلبات'),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(lang.translate('clear_history') ?? 'مسح السجل'),
                    content: Text(lang.translate('clear_history_confirm') ?? 'هل تريد مسح جميع الطلبات؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(lang.translate('cancel') ?? 'إلغاء'),
                      ),
                      TextButton(
                        onPressed: () {
                          context.read<RequestProvider>().clearHistory();
                          Navigator.pop(context);
                        },
                        child: Text(
                          lang.translate('clear') ?? 'مسح',
                          style: TextStyle(color: AppTheme.error),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey[300]),
                  SizedBox(height: 16),
                  Text(
                    lang.translate('no_history') ?? 'لا توجد طلبات سابقة',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final request = history[index];
                return _buildTripCard(context, request, isDark, lang);
              },
            ),
    );
  }

  Widget _buildTripCard(BuildContext context, TowRequest request, bool isDark, AppLocalizations lang) {
    final statusText = request.status == 'completed'
        ? lang.translate('completed') ?? 'مكتملة'
        : lang.translate('cancelled') ?? 'ملغية';
    final statusColor = request.status == 'completed' ? Colors.green : AppTheme.error;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      color: isDark ? AppTheme.darkSurface : Colors.white,
      child: InkWell(
        onTap: () => _showTripDetails(context, request),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: AppTheme.textSecondary),
                      SizedBox(width: 8),
                      Text(
                        '${request.createdAt.day}/${request.createdAt.month}/${request.createdAt.year}',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        '${request.createdAt.hour}:${request.createdAt.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              Row(
                children: [
                  Icon(
                    _getVehicleIcon(request.vehicleType),
                    color: AppTheme.primary,
                    size: 32,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConfig.vehicleCategories[request.vehicleType] ?? request.vehicleType,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${lang.translate('pickup') ?? 'موقع العطل'} → ${lang.translate('dropoff') ?? 'الوجهة'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${request.price.round()} ${AppConfig.currency}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 0.3, duration: 300.ms);
  }
}
