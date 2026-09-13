import 'package:flutter/material.dart';
import '../../../core/network/socket_client.dart';
import '../../../models/tow_request_model.dart';

class RequestProvider extends ChangeNotifier {
  TowRequestModel? _currentRequest;
  final List<OfferModel> _offers = [];
  bool _isPublishing = false;
  bool _isWaitingOffers = false;
  String? _lastError;
  String? _completedTripId;

  TowRequestModel? get currentRequest => _currentRequest;
  List<OfferModel> get offers => List.unmodifiable(_offers);
  bool get isPublishing => _isPublishing;
  bool get isWaitingOffers => _isWaitingOffers;
  String? get lastError => _lastError;
  String? get completedTripId => _completedTripId;

  /// يجب استدعاؤها مرة واحدة بعد اتصال Socket (مثلاً من الشاشة الرئيسية)
  /// لتسجيل الاستماع لأحداث العروض والتحديثات.
  void attachSocketListeners() {
    final socket = SocketClient.instance.socket;

    socket.off('new:offer');
    socket.on('new:offer', (data) {
      _offers.add(OfferModel.fromJson(Map<String, dynamic>.from(data)));
      _isWaitingOffers = true;
      notifyListeners();
    });

    socket.off('request:created');
    socket.on('request:created', (_) {
      _isPublishing = false;
      _isWaitingOffers = true;
      notifyListeners();
    });

    socket.off('offer:accepted');
    socket.on('offer:accepted', (_) {
      if (_currentRequest != null) _currentRequest!.status = 'accepted';
      _isWaitingOffers = false;
      notifyListeners();
    });

    socket.off('trip:completed');
    socket.on('trip:completed', (data) {
      if (_currentRequest != null) _currentRequest!.status = 'completed';
      if (data is Map && data['tripId'] != null) {
        _completedTripId = data['tripId'].toString();
      }
      notifyListeners();
    });

    socket.off('error');
    socket.on('error', (data) {
      _lastError = data is Map ? data['message']?.toString() : 'حدث خطأ';
      _isPublishing = false;
      notifyListeners();
    });
  }

  void publishRequest({
    required String vehicleType,
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    required double price,
  }) {
    _isPublishing = true;
    _offers.clear();
    _isWaitingOffers = false;
    _lastError = null;

    _currentRequest = TowRequestModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      vehicleCategory: vehicleType,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropoffLat: dropoffLat,
      dropoffLng: dropoffLng,
      price: price,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    notifyListeners();

    SocketClient.instance.socket.emit('request:tow', {
      'vehicleType': vehicleType,
      'pickup': {'lat': pickupLat, 'lng': pickupLng},
      'dropoff': {'lat': dropoffLat, 'lng': dropoffLng},
      'price': price,
    });
  }

  void acceptOffer(OfferModel offer) {
    SocketClient.instance.socket.emit('offer:accept', {
      'offerId': offer.id,
      'requestId': offer.requestId,
      'providerId': offer.providerId,
    });
    _currentRequest?.status = 'accepted';
    _isWaitingOffers = false;
    notifyListeners();
  }

  void reset() {
    _currentRequest = null;
    _offers.clear();
    _isWaitingOffers = false;
    _isPublishing = false;
    _lastError = null;
    notifyListeners();
  }
}
