import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../app_config.dart';
import 'token_storage.dart';

/// عميل Socket.IO موحّد. يوفّر:
/// - اتصالاً واحداً يُعاد استخدامه في كل التطبيق
/// - حقن توكن الجلسة في مصافحة الاتصال (auth) بدل الثقة بـ userId من العميل
/// - إعادة تسجيل تلقائية عند إعادة الاتصال (reconnect) حتى لا يفقد
///   السائق حالة "متصل" بصمت بعد انقطاع مؤقت للشبكة
class SocketClient {
  SocketClient._();
  static final SocketClient instance = SocketClient._();

  io.Socket? _socket;
  String? _currentUserId;

  Future<io.Socket> connect(String userId) async {
    _currentUserId = userId;
    final token = await TokenStorage.getToken();

    _socket?.dispose();
    _socket = io.io(
      AppConfig.serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionAttempts(999)
          .setReconnectionDelay(1500)
          .build(),
    );

    _socket!.onConnect((_) => _socket!.emit('register', userId));
    _socket!.onReconnect((_) => _socket!.emit('register', _currentUserId));

    return _socket!;
  }

  io.Socket get socket {
    if (_socket == null) {
      throw StateError('Socket غير متصل بعد. استدعِ connect() أولاً.');
    }
    return _socket!;
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
