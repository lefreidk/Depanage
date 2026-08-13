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

  RequestProvider() {
    _setupSocketListeners();
  }

  // تهيئة مستمعي الأحداث القادمة من الخادم
  void _setupSocketListeners() {
    final socket = SocketService.socket;

    // استقبال عرض سعر جديد من مزود
    socket.on('new:offer', (data) {
      final offer = Offer.fromJson({
        'id': data['offerId'] ?? '',
        'requestId': data['requestId'] ?? '',
        'providerId': data['providerId'] ?? '',
        'providerName': data['providerName'] ?? 'مزود خدمة',
        'price': (data['price'] ?? 0).toDouble(),
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
        'distanceKm': (data['distance'] as num?)?.toDouble(),
      });
      receiveOffer(offer);
    });

    // تأكيد إنشاء الطلب
    socket.on('request:created', (data) {
      _isRequesting = false;
      _isWaitingOffers = true;
      notifyListeners();
    });

    // قبول العرض من قبل العميل (رد من الخادم)
    socket.on('offer:accepted', (data) {
      _currentRequest?.status = 'accepted';
      _isWaitingOffers = false;
      notifyListeners();
    });

    // تحديث موقع السائق (للتتبع) - يمكن استخدامه لاحقاً
    socket.on('provider:location:update', (data) {
      // لا نتعامل معه هنا مباشرة، لكن يمكن للمزود تتبع الشاشة
    });
  }

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
    _isWaitingOffers = false;
    notifyListeners();

    // إنشاء كائن الطلب محلياً
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

    // إرسال الطلب إلى الخادم
    SocketService.emitTowRequest(
      driverId: driverId,
      vehicleType: vehicleType,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropoffLat: dropoffLat,
      dropoffLng: dropoffLng,
      price: price,
    );

    // لا ننتظر استجابة فورية؛ سيصل حدث 'request:created' من الخادم
    // لكن في حال لم يصل، نبقى في حالة الانتظار
    _isRequesting = true;
    notifyListeners();
  }

  // استقبال عرض سعر من مزود
  void receiveOffer(Offer offer) {
    _offers.add(offer);
    _isWaitingOffers = true;
    notifyListeners();
  }

  // قبول عرض سعر
  void acceptOffer(Offer offer) {
    // إرسال قبول العرض إلى الخادم
    SocketService.emitAcceptOffer(
      offerId: offer.id,
      requestId: offer.requestId,
      providerId: offer.providerId,
    );

    // تحديث الحالة محلياً
    _currentRequest?.status = 'accepted';
    _isWaitingOffers = false;
    _offers.clear();
    notifyListeners();
  }

  // إكمال الرحلة (تسمى من شاشة التتبع/التقييم)
  void completeRequest() {
    if (_currentRequest != null) {
      _currentRequest!.status = 'completed';
      _history.insert(0, _currentRequest!);
      _currentRequest = null;
      _offers.clear();
      _isWaitingOffers = false;
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
