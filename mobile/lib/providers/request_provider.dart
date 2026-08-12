import 'package:flutter/material.dart';
import '../models/tow_request.dart';
import '../models/offer.dart';
import '../services/socket_service.dart';

class RequestProvider extends ChangeNotifier {
  TowRequest? _currentRequest;
  List<Offer> _offers = [];
  List<TowRequest> _history = [];
  bool _isRequesting = false;
  bool _isWaitingOffers = false;

  TowRequest? get currentRequest => _currentRequest;
  List<Offer> get offers => _offers;
  List<TowRequest> get history => _history;
  bool get isRequesting => _isRequesting;
  bool get isWaitingOffers => _isWaitingOffers;

  // إنشاء طلب جديد وإرساله عبر Socket.IO
  Future<void> createRequest({
    required String driverId,
    required String vehicleType,
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    required double price,
  }) async {
    _isRequesting = true;
    _offers.clear();
    notifyListeners();

    // إنشاء كائن الطلب محليًا
    _currentRequest = TowRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      vehicleType: vehicleType,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropoffLat: dropoffLat,
      dropoffLng: dropoffLng,
      price: price,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    // إرسال الطلب إلى الخادم عبر Socket.IO
    SocketService.emitTowRequest(
      driverId: driverId,
      vehicleType: vehicleType,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropoffLat: dropoffLat,
      dropoffLng: dropoffLng,
      price: price,
    );

    _isRequesting = false;
    _isWaitingOffers = true;
    notifyListeners();
  }

  // استقبال عرض سعر من مزود خدمة
  void receiveOffer(Offer offer) {
    _offers.add(offer);
    notifyListeners();
  }

  // قبول عرض سعر
  void acceptOffer(Offer offer) {
    // تحديث حالة العرض
    offer = Offer(
      id: offer.id,
      requestId: offer.requestId,
      providerId: offer.providerId,
      providerName: offer.providerName,
      price: offer.price,
      status: 'accepted',
      createdAt: offer.createdAt,
      distanceKm: offer.distanceKm,
    );

    // إرسال قبول العرض إلى الخادم
    SocketService.emitAcceptOffer(
      offerId: offer.id,
      requestId: offer.requestId,
      providerId: offer.providerId,
    );

    // تحديث حالة الطلب
    _currentRequest?.status = 'accepted';
    _isWaitingOffers = false;

    // مسح العروض الأخرى
    _offers.clear();
    notifyListeners();
  }

  // إكمال الطلب (يُستدعى بعد وصول الونش)
  void completeRequest() {
    if (_currentRequest != null) {
      _currentRequest!.status = 'completed';
      _history.insert(0, _currentRequest!);
      _currentRequest = null;
      _offers.clear();
      notifyListeners();
    }
  }

  // إلغاء الطلب الحالي
  void cancelRequest() {
    _currentRequest?.status = 'cancelled';
    _currentRequest = null;
    _offers.clear();
    _isWaitingOffers = false;
    notifyListeners();
  }

  // مسح سجل الطلبات
  void clearHistory() {
    _history.clear();
    notifyListeners();
  }
}
