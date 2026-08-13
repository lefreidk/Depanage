import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config.dart';

class SocketService {
  static IO.Socket? _socket;

  // الحصول على كائن Socket (إنشاء إذا لم يوجد)
  static IO.Socket get socket {
    _socket ??= IO.io(
      AppConfig.serverUrl,
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
      },
    );
    return _socket!;
  }

  // الاتصال بالخادم
  static void connect() {
    if (!socket.connected) {
      socket.connect();
    }
  }

  // قطع الاتصال
  static void disconnect() {
    if (socket.connected) {
      socket.disconnect();
    }
  }

  // تسجيل المستخدم (بمعرّفه) لاستقبال الأحداث الخاصة به
  static void registerUser(String userId) {
    socket.emit('register', userId);
  }

  // إرسال طلب ونش من العميل
  static void emitTowRequest({
    required String driverId,
    required String vehicleType,
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    required double price,
  }) {
    socket.emit('request:tow', {
      'driverId': driverId,
      'vehicleType': vehicleType,
      'pickup': {'lat': pickupLat, 'lng': pickupLng},
      'dropoff': {'lat': dropoffLat, 'lng': dropoffLng},
      'price': price,
    });
  }

  // إرسال عرض سعر من السائق
  static void emitOffer({
    required String requestId,
    required String providerId,
    required double price,
  }) {
    socket.emit('offer:make', {
      'requestId': requestId,
      'providerId': providerId,
      'price': price,
    });
  }

  // قبول عرض سعر من العميل
  static void emitAcceptOffer({
    required String offerId,
    required String requestId,
    required String providerId,
  }) {
    socket.emit('offer:accept', {
      'offerId': offerId,
      'requestId': requestId,
      'providerId': providerId,
    });
  }

  // تحديث موقع السائق (يستخدم من تطبيق السائق)
  static void emitProviderLocation({
    required String userId,
    required double lat,
    required double lng,
  }) {
    socket.emit('provider:location', {
      'userId': userId,
      'lat': lat,
      'lng': lng,
    });
  }
}
