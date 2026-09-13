const { verifyToken } = require('../utils/jwt');
const onlineUsers = require('./onlineUsers');
const { registerRequestHandlers } = require('./requestHandlers');

// يربط Socket.IO بمصادقة JWT حقيقية: أي اتصال بلا توكن صالح
// يُرفض قبل الوصول لأي معالج حدث. هذا يستبدل الثقة السابقة بـ
// userId خام قادم من العميل بدون أي تحقق.
function initSockets(io) {
  io.use((socket, next) => {
    try {
      const token = socket.handshake.auth?.token;
      if (!token) return next(new Error('unauthorized'));

      const payload = verifyToken(token);
      socket.user = payload; // { userId, phone, role }
      next();
    } catch (e) {
      next(new Error('unauthorized'));
    }
  });

  io.on('connection', (socket) => {
    console.log('👤 اتصال جديد:', socket.user.userId);

    socket.on('register', (userId) => {
      // نتجاهل أي userId مرسل من العميل يختلف عن هوية التوكن الموقّع
      const trustedId = socket.user.userId.toString();
      onlineUsers.set(trustedId, socket.id);
      socket.userId = trustedId;
    });

    registerRequestHandlers(io, socket);

    socket.on('disconnect', () => {
      if (socket.userId) {
        onlineUsers.delete(socket.userId);
        console.log('👋 مستخدم غادر:', socket.userId);
      }
    });
  });
}

module.exports = initSockets;
