process.on('uncaughtException', (err) => console.error('❌ خطأ غير متوقع:', err));
process.on('unhandledRejection', (reason) => console.error('❌ وعد مرفوض غير معالج:', reason));

const http = require('http');
const { Server } = require('socket.io');

const app = require('./src/app');
const env = require('./src/config/env');
const initSockets = require('./src/sockets');

const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: env.corsOrigins.length > 0 ? env.corsOrigins : true },
});

initSockets(io);

server.listen(env.port, () => {
  console.log(`🚀 خادم ديباناج يعمل على المنفذ ${env.port}`);
});
