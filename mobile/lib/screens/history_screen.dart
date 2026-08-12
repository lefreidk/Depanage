import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/request_provider.dart';
import '../theme.dart';
import '../config.dart';
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
              // مقبض
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

              // عنوان
              Text(
                'تفاصيل الرحلة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 16),

              // المسار
              _buildInfoRow(
                icon: Icons.car_repair,
                label: 'الانطلاق',
                value: 'موقع العطل',
                isDark: isDark,
              ),
              SizedBox(height: 8),
              _buildInfoRow(
                icon: Icons.flag,
                label: 'الوصول',
                value: 'الوجهة النهائية',
                isDark: isDark,
              ),
              Divider(height: 24, color: Colors.grey.shade300),
              _buildInfoRow(
                icon: Icons.person,
                label: 'السائق',
                value: request.providerName ?? 'غير محدد',
                isDark: isDark,
              ),
              SizedBox(height: 8),
              _buildInfoRow(
                icon: Icons.local_shipping,
                label: 'اللوحة',
                value: request.providerPlate ?? 'غير محدد',
                isDark: isDark,
              ),
              SizedBox(height: 8),
              _buildInfoRow(
                icon: Icons.payments,
                label: 'التكلفة',
                value: '${request.price.round()} ${AppConfig.currency}',
                isDark: isDark,
              ),
              SizedBox(height: 24),

              // زر إعادة الطلب
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _reorder(context, request);
                  },
                  icon: Icon(Icons.replay),
                  label: Text('إعادة الطلب'),
                ),
              ),
              SizedBox(height: 8),

              // زر الاتصال بالدعم
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _openSupportWhatsApp(context);
                  },
                  icon: Icon(Icons.support_agent, color: Colors.green),
                  label: Text('الاتصال بالدعم الفني'),
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

  // أيقونة فئة المركبة
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

    return Scaffold(
      appBar: AppBar(
        title: Text('سجل الطلبات'),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('مسح السجل'),
                    content: Text('هل تريد مسح جميع الطلبات؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('إلغاء'),
                      ),
                      TextButton(
                        onPressed: () {
                          context.read<RequestProvider>().clearHistory();
                          Navigator.pop(context);
                        },
                        child: Text('مسح', style: TextStyle(color: AppTheme.error)),
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
                    'لا توجد طلبات سابقة',
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
                return _buildTripCard(context, request, isDark);
              },
            ),
    );
  }

  // بطاقة الرحلة
  Widget _buildTripCard(BuildContext context, TowRequest request, bool isDark) {
    final statusText = request.status == 'completed' ? 'مكتملة' : 'ملغية';
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
              // التاريخ والحالة
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

              // أيقونة الفئة والتكلفة
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
                          'موقع العطل → الوجهة',
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
