import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/request_provider.dart';
import '../models/offer.dart';
import '../theme.dart';
import '../localizations/app_localizations.dart';
import '../widgets/offer_card.dart';
import 'tracking_screen.dart';

class RequestScreen extends StatefulWidget {
  @override
  _RequestScreenState createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
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
    final lang = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('offers') ?? 'عروض السائقين'),
        actions: [
          if (requestProv.offers.isEmpty && requestProv.isWaitingOffers)
            TextButton(
              onPressed: () {
                requestProv.cancelRequest();
                Navigator.pop(context);
              },
              child: Text(
                lang.translate('cancel') ?? 'إلغاء',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: requestProv.offers.isEmpty
          ? _buildWaitingState(isDark, lang)
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: requestProv.offers.length,
              itemBuilder: (context, index) {
                final offer = requestProv.offers[index];
                return OfferCard(
                  offer: offer,
                  onAccept: () => _acceptOffer(offer),
                );
              },
            ),
    );
  }

  // حالة انتظار العروض
  Widget _buildWaitingState(bool isDark, AppLocalizations lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
            lang.translate('waiting_offers') ?? 'جاري البحث عن سائقين قريبين...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            lang.translate('offer_notification') ?? 'سيصلك إشعار فور وصول أول عرض',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}
