import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/request_provider.dart';
import '../theme.dart';
import '../config.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final requestProv = context.watch<RequestProvider>();
    final history = requestProv.history;

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
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final request = history[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getStatusIcon(request.status),
                              color: _getStatusColor(request.status),
                            ),
                            SizedBox(width: 8),
                            Text(
                              _getStatusText(request.status),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(request.status),
                              ),
                            ),
                            Spacer(),
                            Text(
                              '${request.price.round()} ${AppConfig.currency}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: AppTheme.textSecondary),
                            SizedBox(width: 8),
                            Text(
                              '${request.createdAt.day}/${request.createdAt.month}/${request.createdAt.year}',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.directions_car, size: 16, color: AppTheme.textSecondary),
                            SizedBox(width: 8),
                            Text(request.vehicleType),
                          ],
                        ),
                        if (request.providerName != null) ...[
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.person, size: 16, color: AppTheme.textSecondary),
                              SizedBox(width: 8),
                              Text('المزود: ${request.providerName}'),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'accepted':
        return Icons.local_shipping;
      case 'pending':
        return Icons.hourglass_empty;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'accepted':
        return AppTheme.primary;
      case 'pending':
        return AppTheme.accent;
      case 'cancelled':
        return AppTheme.error;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'مكتمل';
      case 'accepted':
        return 'مقبول';
      case 'pending':
        return 'قيد الانتظار';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }
}
