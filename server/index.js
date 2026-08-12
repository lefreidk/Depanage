// معالجة الأخطاء غير المتوقعة
process.on('uncaughtException', (err) => {
  console.error('❌ خطأ غير متوقع:', err);
});
process.on('unhandledRejection', (reason) => {
  console.error('❌ وعد مرفوض غير معالج:', reason);
});

require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');
const { Redis } = require('@upstash/redis');

const app = express();
app.use(cors());
app.use(express.json());

const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*' } });

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

const redis = new Redis({
  url: process.env.UPSTASH_REDIS_URL,
  token: process.env.UPSTASH_REDIS_TOKEN,
});

const GREEN_API_ID = process.env.GREEN_API_ID_INSTANCE;
const GREEN_API_TOKEN = process.env.GREEN_API_API_TOKEN_INSTANCE;

console.log('✅ تم الاتصال بـ Supabase و Redis');
console.log('GREEN_API_ID:', GREEN_API_ID ? 'موجود' : 'مفقود');
console.log('GREEN_API_TOKEN:', GREEN_API_TOKEN ? 'موجود' : 'مفقود');

// تخزين OTP في الذاكرة (بدل Redis)
const otpStore = new Map(); // key: cleanPhone, value: { otp, expiresAt }

// إرسال رسالة واتساب عبر Green API
async function sendWhatsAppOtp(phone, otp) {
  try {
    const cleanPhone = phone.replace(/[^0-9]/g, '');
    const url = `https://7107.api.greenapi.com/waInstance${GREEN_API_ID}/SendMessage/${GREEN_API_TOKEN}`;
    const body = {
      chatId: `${cleanPhone}@c.us`,
      message: `رمز التحقق الخاص بك هو: ${otp}`
    };
    console.log('📤 إرسال OTP إلى:', cleanPhone);
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    });
    const text = await res.text();
    console.log('📩 استجابة Green API:', res.status, text);
    return res.ok;
  } catch (e) {
    console.error('❌ خطأ في إرسال واتساب:', e);
    return false;
  }
}

function generateOtp() {
  return Math.floor(1000 + Math.random() * 9000).toString();
}

app.get('/', (req, res) => {
  res.send('ديباناج يعمل! 🚛');
});

// إرسال OTP
app.post('/api/auth/send-otp', async (req, res) => {
  const { phone } = req.body;
  if (!phone) return res.status(400).json({ error: 'رقم الهاتف مطلوب' });

  const cleanPhone = phone.replace(/[^0-9]/g, '');
  const otp = generateOtp();

  // حفظ الرمز في الذاكرة لمدة 5 دقائق
  otpStore.set(cleanPhone, { otp, expiresAt: Date.now() + 5 * 60 * 1000 });
  console.log('💾 حفظ OTP لـ', cleanPhone, 'الرمز:', otp);

  const sent = await sendWhatsAppOtp(phone, otp);

  if (sent) {
    res.json({ success: true, message: 'تم إرسال الرمز' });
  } else {
    res.status(500).json({ error: 'فشل إرسال الرمز' });
  }
});

// التحقق من OTP
app.post('/api/auth/verify-otp', async (req, res) => {
  const { phone, otp } = req.body;
  if (!phone || !otp) return res.status(400).json({ error: 'بيانات ناقصة' });

  const cleanPhone = phone.replace(/[^0-9]/g, '');
  const cleanOtp = otp.trim();

  const stored = otpStore.get(cleanPhone);
  console.log('🔍 التحقق من OTP لـ', cleanPhone, 'المدخل:', cleanOtp, 'المخزن:', stored ? stored.otp : 'غير موجود');

  if (!stored) {
    return res.status(400).json({ error: 'انتهت صلاحية الرمز أو لم يتم إرساله' });
  }

  if (Date.now() > stored.expiresAt) {
    otpStore.delete(cleanPhone);
    return res.status(400).json({ error: 'انتهت صلاحية الرمز' });
  }

  if (stored.otp === cleanOtp) {
    otpStore.delete(cleanPhone);
    res.json({ success: true, userId: cleanPhone, phone: cleanPhone });
  } else {
    res.status(400).json({ error: 'رمز التحقق غير صحيح' });
  }
});

// خريطة المستخدمين المتصلين
const onlineUsers = new Map();

// أحداث Socket.IO
io.on('connection', (socket) => {
  console.log('👤 متصل:', socket.id);

  socket.on('register', (userId) => {
    onlineUsers.set(userId.toString(), socket.id);
    socket.userId = userId;
    console.log(`✅ مستخدم ${userId} مسجل`);
  });

  socket.on('provider:location', async (data) => {
    try {
      const { userId, lat, lng } = data;
      await redis.geoadd('providers:locations', {
        longitude: lng,
        latitude: lat,
        member: userId.toString()
      });
      console.log('📍 تحديث موقع مزود:', userId, lat, lng);
    } catch (e) {
      console.error('❌ خطأ في حفظ موقع المزود:', e);
    }
  });

  socket.on('request:tow', async (data) => {
    try {
      const { driverId, vehicleType, pickup, dropoff, price } = data;

      const { data: request, error } = await supabase
        .from('tow_requests')
        .insert([{
          driver_id: driverId,
          vehicle_type: vehicleType,
          pickup_lat: pickup.lat,
          pickup_lng: pickup.lng,
          dropoff_lat: dropoff.lat,
          dropoff_lng: dropoff.lng,
          price: price,
          status: 'pending'
        }])
        .select()
        .single();

      if (error) throw error;

      const requestId = request.id;
      console.log('🆕 طلب جديد:', requestId);

      let sentCount = 0;
      for (const [providerId, socketId] of onlineUsers) {
        if (providerId !== driverId.toString()) {
          io.to(socketId).emit('new:request', {
            requestId,
            vehicleType,
            pickup,
            dropoff,
            price,
            distance: 0
          });
          sentCount++;
        }
      }
      console.log(`📨 تم إرسال الطلب إلى ${sentCount} مزود`);

      socket.emit('request:created', { requestId, nearbyCount: sentCount });
    } catch (e) {
      console.error('❌ خطأ في إنشاء الطلب:', e);
      socket.emit('error', { message: 'فشل إنشاء الطلب' });
    }
  });

  socket.on('offer:make', async (data) => {
    try {
      const { requestId, providerId, price } = data;
      const { data: offer, error } = await supabase
        .from('offers')
        .insert([{ request_id: requestId, provider_id: providerId, price: price }])
        .select()
        .single();

      if (error) throw error;

      const { data: request } = await supabase
        .from('tow_requests')
        .select('driver_id')
        .eq('id', requestId)
        .single();

      const driverSocketId = onlineUsers.get(request.driver_id.toString());
      if (driverSocketId) {
        io.to(driverSocketId).emit('new:offer', {
          offerId: offer.id,
          requestId,
          providerId,
          price
        });
      }
      console.log('💵 عرض سعر جديد:', offer.id);
    } catch (e) {
      console.error('❌ خطأ في عرض السعر:', e);
    }
  });

  socket.on('offer:accept', async (data) => {
    try {
      const { offerId, requestId, providerId } = data;
      await supabase.from('offers').update({ status: 'accepted' }).eq('id', offerId);
      await supabase.from('tow_requests').update({ status: 'accepted', provider_id: providerId }).eq('id', requestId);

      const providerSocketId = onlineUsers.get(providerId.toString());
      if (providerSocketId) {
        io.to(providerSocketId).emit('offer:accepted', { requestId });
      }
      console.log('✅ عرض مقبول:', offerId);
    } catch (e) {
      console.error('❌ خطأ في قبول العرض:', e);
    }
  });

  socket.on('disconnect', () => {
    if (socket.userId) {
      onlineUsers.delete(socket.userId.toString());
      console.log(`👋 مستخدم ${socket.userId} غادر`);
    }
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`🚀 خادم ديباناج يعمل على المنفذ ${PORT}`);
});
