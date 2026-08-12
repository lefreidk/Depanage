import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../providers/request_provider.dart';
import '../providers/auth_provider.dart';
import '../services/socket_service.dart';
import '../models/offer.dart';
import '../theme.dart';
import '../config.dart';
import 'tracking_screen.dart';

class RequestScreen extends StatefulWidget {
  @override
  _RequestScreenState createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  IO.Socket? _socket;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _setupSocketListeners();
  }

  // إعداد مستمعي Socket.IO لاستقبال العروض
  void _setupSocketListeners() {
    _socket = SocketService.socket;
    _socket!.on('new:offer', (data) {
      final offer = Offer.fromJson({
        'id': data['offerId'] ?? '',
        'requestId': data['requestId'] ?? '',
        'providerId': data['providerId'] ?? '',
        'providerName': data['providerName'] ?? 'مزود خدمة',
        'price': (data['price'] ?? 0).toDouble(),
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
        'distanceKm': data['distance'],
      });

      context.read<RequestProvider>().receiveOffer(offer);
    });

    _isListening = true;
  }

  @override
  void dispose() {
    _socket?.off('new:offer');
    super.dispose();
  }

  // قبول عرض السعر
  void _acceptOffer(Offer offer) {
    context.read<RequestProvider>().acceptOffer(offer);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TrackingScreen()),
    );
  }

  // إلغاء الطلب
  void _cancelRequest() {
    context.read<RequestProvider>().cancelRequest();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('العروض'),
        actions: [
          TextButton(
            onPressed: _cancelRequest,
            child: Text('إلغاء', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Consumer<RequestProvider>(
        builder: (context, provider, _) {
          if (provider.offers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primary),
                  SizedBox(height: 24),
                  Text('بانتظار العروض...'),
                  SizedBox(height: 8),
                  Text(
                    'سيصلك تنبيه فور وصول عرض من أقرب مزودي الخدمة',
                    style: TextStyle(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: provider.offers.length,
            itemBuilder: (context, index) {
              final offer = provider.offers[index];
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.primary.withOpacity(0.1),
                            child: Icon(Icons.person, color: AppTheme.primary),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  offer.providerName,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (offer.distanceKm != null)
                                  Text(
                                    '${offer.distanceKm!.toStringAsFixed(1)} كم',
                                    style: TextStyle(color: AppTheme.textSecondary),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '${offer.price.round()} ${AppConfig.currency}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _acceptOffer(offer),
                              child: Text('قبول العرض'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
