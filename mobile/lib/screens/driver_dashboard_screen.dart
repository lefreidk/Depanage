import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/auth_provider.dart';
import '../services/socket_service.dart';
import '../theme.dart';
import '../config.dart';
import '../localizations/app_localizations.dart';

class DriverDashboardScreen extends StatefulWidget {
  @override
  _DriverDashboardScreenState createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  List<Map<String, dynamic>> _incomingRequests = [];
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupSocketListeners();
    final auth = context.read<AuthProvider>();
    if (auth.user != null) {
      SocketService.registerUser(auth.user!.id);
    }
  }

  @override
  void dispose() {
    SocketService.socket.off('new:request');
    _priceController.dispose();
    super.dispose();
  }

  void _setupSocketListeners() {
    final socket = SocketService.socket;
    socket.on('new:request', (data) {
      setState(() {
        _incomingRequests.insert(0, data);
      });
    });
  }

  Future<void> _sendOffer(Map<String, dynamic> request) async {
    if (_priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الرجاء إدخال السعر')),
      );
      return;
    }

    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('سعر غير صالح')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final requestId = request['requestId']?.toString() ?? '';

    try {
      SocketService.emitOffer(
        requestId: requestId,
        providerId: auth.user?.id ?? '1',
        price: price,
      );

      setState(() {
        _incomingRequests.removeWhere((r) => r['requestId'] == requestId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إرسال العرض بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل إرسال العرض: $e')),
      );
    } finally {
      _priceController.clear();
    }
  }

  void _showPriceDialog(Map<String, dynamic> request) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(lang.translate('send_offer') ?? 'إرسال عرض سعر'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${lang.translate('vehicle_type') ?? 'نوع المركبة'}: ${request['vehicleType'] ?? ''}',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '${lang.translate('price') ?? 'السعر'} (${AppConfig.currency})',
                  filled: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(lang.translate('cancel') ?? 'إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _sendOffer(request);
              },
              child: Text(lang.translate('send') ?? 'إرسال'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('driver_dashboard') ?? 'لوحة السائق'),
      ),
      body: _incomingRequests.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping, size: 80, color: Colors.grey[300]),
                  SizedBox(height: 16),
                  Text(
                    lang.translate('no_incoming_requests') ?? 'لا توجد طلبات قادمة حالياً',
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
              itemCount: _incomingRequests.length,
              itemBuilder: (context, index) {
                final request = _incomingRequests[index];
                return _buildRequestCard(request, isDark, lang);
              },
            ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request, bool isDark, AppLocalizations lang) {
    final vehicleType = request['vehicleType'] ?? '';
    final pickup = request['pickup'];
    final dropoff = request['dropoff'];
    final price = request['price'];

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      color: isDark ? AppTheme.darkSurface : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_car, color: AppTheme.primary),
                SizedBox(width: 8),
                Text(
                  AppConfig.vehicleCategories[vehicleType] ?? vehicleType,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                Spacer(),
                if (price != null)
                  Text(
                    '${price.toString()} ${AppConfig.currency}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12),
            if (pickup != null)
              Text(
                '${lang.translate('pickup') ?? 'الانطلاق'}: ${pickup['lat']}, ${pickup['lng']}',
                style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
              ),
            if (dropoff != null)
              Text(
                '${lang.translate('dropoff') ?? 'الوصول'}: ${dropoff['lat']}, ${dropoff['lng']}',
                style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
              ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showPriceDialog(request),
                icon: Icon(Icons.attach_money),
                label: Text(lang.translate('send_offer') ?? 'إرسال عرض سعر'),
              ),
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 0.3, duration: 300.ms);
  }
}
