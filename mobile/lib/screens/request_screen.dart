import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/request_provider.dart';
import '../models/offer.dart';
import '../theme.dart';
import '../config.dart';
import 'tracking_screen.dart';

class RequestScreen extends StatefulWidget {
  @override
  _RequestScreenState createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  @override
  void initState() {
    super.initState();
    // لا حاجة لإعداد خاص هنا، المزود يستمع تلقائيًا للعروض
  }

  // قبول عرض سعر
  void _acceptOffer(Offer offer) {
    context.read<RequestProvider>().acceptOffer(offer);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TrackingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requestProv = context.watch<RequestProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('عروض السائقين'),
        actions: [
          // زر إلغاء الطلب
          if (requestProv.offers.isEmpty && requestProv.isWaitingOffers)
            TextButton(
              onPressed: () {
                requestProv.cancelRequest();
                Navigator.pop(context);
              },
              child: Text(
                'إلغاء',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: requestProv.offers.isEmpty
          ? _buildWaitingState(isDark)
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: requestProv.offers.length,
              itemBuilder: (context, index) {
                final offer = requestProv.offers[index];
                return _buildOfferCard(offer, isDark);
              },
            ),
    );
  }

  // حالة انتظار العروض (رادار بحث)
  Widget _buildWaitingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // مؤشر رادار تفاعلي
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  color: AppTheme.primary,
                  strokeWidth: 3,
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.radar,
                    color: AppTheme.primary,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          Text(
            'جاري البحث عن سائقين قريبين...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'سيصلك إشعار فور وصول أول عرض',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  // بطاقة عرض السائق
  Widget _buildOfferCard(Offer offer, bool isDark) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      color: isDark ? AppTheme.darkSurface : Colors.white,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة السائق واسمه وتقييمه
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child: Icon(Icons.person, color: AppTheme.primary, size: 30),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.providerName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '4.5',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.verified, color: Colors.green, size: 16),
                        ],
                      ),
                    ],
                  ),
                ),
                // السعر
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${offer.price.round()} ${AppConfig.currency}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    if (offer.distanceKm != null)
                      Text(
                        '${offer.distanceKm!.toStringAsFixed(1)} كم',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey.shade300),
            SizedBox(height: 12),
            // نوع السطحة والوقت التقديري
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_shipping, color: AppTheme.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'سطحة',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '12345',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.timer, color: AppTheme.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '5 دقائق',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            // زر قبول العرض
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _acceptOffer(offer),
                icon: Icon(Icons.check_circle),
                label: Text('قبول العرض'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 0.3, duration: 400.ms, curve: Curves.easeOut);
  }
}
