// =====================================================
// خادم ديباناج (server/index.js) - النسخة الكاملة
// =====================================================

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
const io = new Server(server, {
  cors: { origin: '*' }
});

// ---------- الاتصال بالخدمات الخارجية ----------
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

// ---------- الإعدادات الثابتة ----------
const COMMISSION_RATE = 0.15; // 15%
const MIN_WALLET_BALANCE = 500; // 500 دج
const PRICE_PER_KM = {
  motorcycle: 300,
  car: 500,
  utility: 500,
  truck: 900,
  heavy_truck: 900,
};
const ADMIN_USERNAME = 'lefreidk';
const ADMIN_PASSWORD = '23022001@@@'; // في الإنتاج يُشفّر

console.log('✅ تم الاتصال بالخدمات');
console.log('GREEN_API_ID:', GREEN_API_ID ? 'موجود' : 'مفقود');
console.log('GREEN_API_TOKEN:', GREEN_API_TOKEN ? 'موجود' : 'مفقود');

// ---------- دوال مساعدة ----------
function generateOtp() {
  return Math.floor(1000 + Math.random() * 9000).toString();
}

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

// ---------- تخزين OTP في الذاكرة ----------
const otpStore = new Map(); // phone -> { otp, expiresAt }

// ---------- نقطة فحص ----------
app.get('/', (req, res) => {
  res.send('ديباناج يعمل! 🚛');
});

// =====================================================
// 1. المصادقة (Auth)
// =====================================================

// إرسال OTP
app.post('/api/auth/send-otp', async (req, res) => {
  const { phone } = req.body;
  if (!phone) return res.status(400).json({ error: 'رقم الهاتف مطلوب' });

  const cleanPhone = phone.replace(/[^0-9]/g, '');
  const otp = generateOtp();

  otpStore.set(cleanPhone, { otp, expiresAt: Date.now() + 5 * 60 * 1000 });

  const sent = await sendWhatsAppOtp(phone, otp);
  if (sent) {
    res.json({ success: true, message: 'تم إرسال الرمز' });
  } else {
    res.status(500).json({ error: 'فشل إرسال الرمز' });
  }
});

// التحقق من OTP وتسجيل الدخول / إنشاء حساب
app.post('/api/auth/verify-otp', async (req, res) => {
  const { phone, otp } = req.body;
  if (!phone || !otp) return res.status(400).json({ error: 'بيانات ناقصة' });

  const cleanPhone = phone.replace(/[^0-9]/g, '');
  const cleanOtp = otp.trim();

  const stored = otpStore.get(cleanPhone);
  if (!stored || Date.now() > stored.expiresAt || stored.otp !== cleanOtp) {
    return res.status(400).json({ error: 'رمز التحقق غير صحيح' });
  }
  otpStore.delete(cleanPhone);

  // البحث عن المستخدم أو إنشائه
  let { data: user } = await supabase
    .from('users')
    .select('*')
    .eq('phone', cleanPhone)
    .single();

  if (!user) {
    const { data: newUser, error } = await supabase
      .from('users')
      .insert([{ phone: cleanPhone, role: 'client' }])
      .select()
      .single();
    if (error) return res.status(500).json({ error: 'فشل إنشاء المستخدم' });
    user = newUser;
  }

  res.json({ success: true, userId: user.id, phone: cleanPhone, role: user.role });
});

// تسجيل دخول الأدمن
app.post('/api/auth/admin-login', async (req, res) => {
  const { username, password } = req.body;
  if (username === ADMIN_USERNAME && password === ADMIN_PASSWORD) {
    res.json({ success: true, message: 'تم تسجيل دخول الأدمن' });
  } else {
    res.status(401).json({ error: 'بيانات الدخول غير صحيحة' });
  }
});

// =====================================================
// 2. طلبات الجر (Client Requests)
// =====================================================

// إنشاء طلب جر
app.post('/api/requests/create', async (req, res) => {
  const {
    userId, vehicleCategory, pickupLat, pickupLng,
    dropoffLat, dropoffLng, price
  } = req.body;

  if (!userId || !pickupLat || !pickupLng || !dropoffLat || !dropoffLng || !price) {
    return res.status(400).json({ error: 'بيانات الطلب ناقصة' });
  }

  const { data: request, error } = await supabase
    .from('tow_requests')
    .insert([{
      client_id: userId,
      vehicle_category: vehicleCategory,
      pickup_lat: pickupLat,
      pickup_lng: pickupLng,
      dropoff_lat: dropoffLat,
      dropoff_lng: dropoffLng,
      price: price,
      status: 'pending'
    }])
    .select()
    .single();

  if (error) return res.status(500).json({ error: 'فشل إنشاء الطلب' });

  res.json({ success: true, requestId: request.id });
});

// سجل طلبات المستخدم
app.get('/api/requests/history', async (req, res) => {
  const { userId } = req.query;
  if (!userId) return res.status(400).json({ error: 'معرف المستخدم مطلوب' });

  const { data: requests, error } = await supabase
    .from('tow_requests')
    .select('*')
    .eq('client_id', userId)
    .order('created_at', { ascending: false })
    .limit(50);

  if (error) return res.status(500).json({ error: 'فشل جلب السجل' });

  res.json(requests);
});

// =====================================================
// 3. ورشات التصليح (Workshops)
// =====================================================

app.get('/api/workshops', async (req, res) => {
  const { data: workshops, error } = await supabase
    .from('workshops')
    .select('*')
    .order('rating', { ascending: false });

  if (error) return res.status(500).json({ error: 'فشل جلب الورشات' });

  res.json(workshops);
});

// =====================================================
// 4. طلب الشراكة للسائقين (Driver Onboarding)
// =====================================================

app.post('/api/drivers/apply', async (req, res) => {
  const {
    userId, fullName, licenseNumber, licenseExpiry,
    plateNumber, vehicleYear, vehicleTypes
  } = req.body;

  if (!userId || !fullName || !licenseNumber || !plateNumber || !vehicleTypes) {
    return res.status(400).json({ error: 'بيانات السائق ناقصة' });
  }

  // تحديث اسم المستخدم
  await supabase.from('users').update({ name: fullName }).eq('id', userId);

  // إنشاء سجل سائق
  const { data: driver, error } = await supabase
    .from('drivers')
    .insert([{
      user_id: userId,
      license_number: licenseNumber,
      license_expiry: licenseExpiry,
      plate_number: plateNumber,
      vehicle_year: vehicleYear,
      vehicle_types: vehicleTypes,
      status: 'pending'
    }])
    .select()
    .single();

  if (error) return res.status(500).json({ error: 'فشل إرسال الطلب' });

  res.json({ success: true, driverId: driver.id });
});

// =====================================================
// 5. لوحة الإدارة (Admin)
// =====================================================

// جلب طلبات الشراكة المعلقة
app.get('/api/admin/drivers/pending', async (req, res) => {
  const { data: drivers, error } = await supabase
    .from('drivers')
    .select('*, users(phone, name)')
    .eq('status', 'pending');

  if (error) return res.status(500).json({ error: 'فشل جلب الطلبات' });

  res.json(drivers);
});

// قبول أو رفض سائق
app.post('/api/admin/drivers/decision', async (req, res) => {
  const { driverId, decision, reason } = req.body;
  const newStatus = decision === 'approve' ? 'approved' : 'rejected';

  const { error } = await supabase
    .from('drivers')
    .update({ status: newStatus, rejection_reason: reason || null })
    .eq('id', driverId);

  if (error) return res.status(500).json({ error: 'فشل تحديث الحالة' });

  res.json({ success: true });
});

// شحن رصيد سائق (بواسطة رقم الهاتف)
app.post('/api/admin/wallets/charge', async (req, res) => {
  const { phone, amount } = req.body;
  if (!phone || !amount) return res.status(400).json({ error: 'بيانات ناقصة' });

  // البحث عن المستخدم برقم الهاتف
  const { data: user } = await supabase
    .from('users')
    .select('id')
    .eq('phone', phone)
    .single();

  if (!user) return res.status(404).json({ error: 'السائق غير موجود' });

  // تحديث المحفظة
  const { data: wallet } = await supabase
    .from('wallets')
    .select('balance')
    .eq('user_id', user.id)
    .single();

  const newBalance = (wallet?.balance || 0) + parseFloat(amount);

  const { error: upsertError } = await supabase
    .from('wallets')
    .upsert({ user_id: user.id, balance: newBalance });

  if (upsertError) return res.status(500).json({ error: 'فشل تحديث المحفظة' });

  // تسجيل المعاملة
  await supabase.from('transactions').insert([{
    user_id: user.id,
    amount: parseFloat(amount),
    type: 'credit',
    reason: 'شحن رصيد من الإدارة'
  }]);

  res.json({ success: true, newBalance });
});

// =====================================================
// 6. Socket.IO (التواصل الفوري)
// =====================================================

const onlineUsers = new Map(); // userId -> socketId

io.on('connection', (socket) => {
  console.log('👤 متصل:', socket.id);

  socket.on('register', (userId) => {
    onlineUsers.set(userId.toString(), socket.id);
    socket.userId = userId;
    console.log(`✅ مستخدم ${userId} مسجل`);
  });

  // سائق يحدّث موقعه
  socket.on('provider:location', async (data) => {
    try {
      const { userId, lat, lng } = data;
      await redis.geoadd('providers:locations', {
        longitude: lng,
        latitude: lat,
        member: userId.toString()
      });
    } catch (e) {
      console.error('❌ خطأ في حفظ الموقع:', e);
    }
  });

  // عميل ينشئ طلب جر
  socket.on('request:tow', async (data) => {
    try {
      const { driverId, vehicleType, pickup, dropoff, price } = data;

      const { data: request } = await supabase
        .from('tow_requests')
        .insert([{
          client_id: driverId,
          vehicle_category: vehicleType,
          pickup_lat: pickup.lat,
          pickup_lng: pickup.lng,
          dropoff_lat: dropoff.lat,
          dropoff_lng: dropoff.lng,
          price: price,
          status: 'pending'
        }])
        .select()
        .single();

      let sentCount = 0;
      for (const [providerId, socketId] of onlineUsers) {
        if (providerId !== driverId.toString()) {
          io.to(socketId).emit('new:request', {
            requestId: request.id,
            vehicleType,
            pickup,
            dropoff,
            price
          });
          sentCount++;
        }
      }

      socket.emit('request:created', { requestId: request.id, nearbyCount: sentCount });
    } catch (e) {
      console.error('❌ خطأ في إنشاء الطلب:', e);
      socket.emit('error', { message: 'فشل إنشاء الطلب' });
    }
  });

  // سائق يقدم عرضًا
  socket.on('offer:make', async (data) => {
    try {
      const { requestId, providerId, price } = data;
      const { data: offer } = await supabase
        .from('offers')
        .insert([{ request_id: requestId, driver_id: providerId, price }])
        .select()
        .single();

      const { data: request } = await supabase
        .from('tow_requests')
        .select('client_id')
        .eq('id', requestId)
        .single();

      const clientSocketId = onlineUsers.get(request.client_id.toString());
      if (clientSocketId) {
        io.to(clientSocketId).emit('new:offer', {
          offerId: offer.id,
          requestId,
          providerId,
          price
        });
      }
    } catch (e) {
      console.error('❌ خطأ في إرسال العرض:', e);
    }
  });

  socket.on('disconnect', () => {
    if (socket.userId) {
      onlineUsers.delete(socket.userId.toString());
      console.log(`👋 مستخدم ${socket.userId} غادر`);
    }
  });
});

// =====================================================
// تشغيل الخادم
// =====================================================
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`🚀 خادم ديباناج يعمل على المنفذ ${PORT}`);
});
