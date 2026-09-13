import 'package:flutter/material.dart';
import '../../../core/network/socket_client.dart';

class IncomingRequest {
  final String requestId;
  final String vehicleType;
  final Map<String, dynamic> pickup;
  final Map<String, dynamic> dropoff;
  final double price;

  IncomingRequest({
    required this.requestId,
    required this.vehicleType,
    required this.pickup,
    required this.dropoff,
    required this.price,
  });

  factory IncomingRequest.fromSocket(Map data) {
    return IncomingRequest(
      requestId: data['requestId'].toString(),
      vehicleType: data['vehicleType'] ?? '',
      pickup: Map<String, dynamic>.from(data['pickup'] ?? {}),
      dropoff: Map<String, dynamic>.from(data['dropoff'] ?? {}),
      price: (data['price'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DriverProvider extends ChangeNotifier {
  final List<IncomingRequest> _incomingRequests = [];
  String? _activeRequestId;
  bool _hasActiveTrip = false;

  List<IncomingRequest> get incomingRequests => List.unmodifiable(_incomingRequests);
  bool get hasActiveTrip => _hasActiveTrip;

  void attachSocketListeners() {
    final socket = SocketClient.instance.socket;

    socket.off('new:request');
    socket.on('new:request', (data) {
      _incomingRequests.insert(0, IncomingRequest.fromSocket(Map.from(data)));
      notifyListeners();
    });

    socket.off('offer:accepted');
    socket.on('offer:accepted', (data) {
      _activeRequestId = data['requestId']?.toString();
      _hasActiveTrip = true;
      notifyListeners();
    });

    socket.off('trip:completed');
    socket.on('trip:completed', (_) {
      _hasActiveTrip = false;
      _activeRequestId = null;
      notifyListeners();
    });
  }

  void sendOffer(String requestId, double price) {
    SocketClient.instance.socket.emit('offer:make', {'requestId': requestId, 'price': price});
    _incomingRequests.removeWhere((r) => r.requestId == requestId);
    notifyListeners();
  }

  void shareLocation(double lat, double lng) {
    SocketClient.instance.socket.emit('provider:location', {'lat': lat, 'lng': lng});
  }

  void completeActiveTrip() {
    if (_activeRequestId == null) return;
    SocketClient.instance.socket.emit('trip:complete', {'requestId': _activeRequestId});
  }
}
