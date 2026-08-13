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
app.use(express.json({ limit: '10mb' }));

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

// ---------- نقطة فحص ----------
app.get('/', (req, res) => {
  res.send('ديباناج يعمل! 🚛');
});

// =====================================================
// 1. المصادقة (Auth)
// =====================================================

app.post('/api/auth/send-otp', async (req, res) => {
  const { phone } = req.body;
  if (!phone) return res.status(400).json({ error: 'رقم الهاتف مطلوب' });

  const cleanPhone = phone.replace(/[^0-9]/g, '');
  const otp = generateOtp();

  try {
    // حفظ الرمز في Upstash Redis لمدة 5 دقائق
    await redis.set(`otp:${cleanPhone}`, otp, { ex: 300 });
    console.log('💾 حفظ OTP لـ', cleanPhone, 'الرمز:', otp);

    const sent = await sendWhatsAppOtp(phone, otp);
    if (sent) {
      res.json({ success: true, message: 'تم إرسال الرمز' });
    } else {
      res.status(500).json({ error: 'فشل إرسال الرمز' });
    }
  } catch (e) {
    console.error('❌ خطأ في إرسال OTP:', e);
    res.status(500).json({ error: 'خطأ في الخادم' });
  }
});

app.post('/api/auth/verify-otp', async (req, res) => {
  const { phone, otp } = req.body;
  if (!phone || !otp) return res.status(400).json({ error: 'بيانات ناقصة' });

  const cleanPhone = phone.replace(/[^0-9]/g, '');
  const cleanOtp = otp.trim();

  try {
    const storedRaw = await redis.get(`otp:${cleanPhone}`);
    const stored = String(storedRaw ?? '').trim();

    console.log('🔍 التحقق من OTP لـ', cleanPhone, 'المدخل:', cleanOtp, 'المخزن:', stored);

    if (stored === cleanOtp) {
      await redis.del(`otp:${cleanPhone}`);
      res.json({ success: true, userId: cleanPhone, phone: cleanPhone });
    } else {
      res.status(400).json({ error: 'رمز التحقق غير صحيح' });
    }
  } catch (e) {
    console.error('❌ خطأ في التحقق:', e);
    res.status(500).json({ error: 'خطأ في الخادم' });
  }
});

// تسجيل دخول الأدمن
app.post('/api/auth/admin-login', async (req, res) => {
  const { username, password } = req.body;
  if (username === 'lefreidk' && password === '23022001@@@') {
    res.json({ success: true, message: 'تم تسجيل دخول الأدمن' });
  } else {
    res.status(401).json({ error: 'بيانات الدخول غير صحيحة' });
  }
});

// =====================================================
// 2. طلبات الجر (Client Requests)
// =====================================================

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
// 4. طلب الشراكة للسائقين (Driver Onboarding) مع رفع الوثائق
// =====================================================

async function uploadDocument(driverId, type, base64String) {
  if (!base64String) return null;

  const cleanBase64 = base64String.replace(/^data:image\/\w+;base64,/, '');
  const buffer = Buffer.from(cleanBase64, 'base64');
  const fileName = `${driverId}/${type}_${Date.now()}.png`;

  const { data, error } = await supabase.storage
    .from('documents')
    .upload(fileName, buffer, {
      contentType: 'image/png',
      upsert: false,
    });

  if (error) {
    console.error('❌ فشل رفع الوثيقة:', error);
    return null;
  }

  const { data: publicUrl } = supabase.storage
    .from('documents')
    .getPublicUrl(fileName);

  return publicUrl.publicUrl;
}

app.post('/api/drivers/apply', async (req, res) => {
  const {
    userId, fullName, licenseNumber, licenseExpiry,
    plateNumber, vehicleYear, vehicleTypes, documents
  } = req.body;

  if (!userId || !fullName || !licenseNumber || !plateNumber || !vehicleTypes) {
    return res.status(400).json({ error: 'بيانات السائق ناقصة' });
  }

  try {
    await supabase.from('users').update({ name: fullName }).eq('id', userId);

    const { data: driver, error: driverError } = await supabase
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

    if (driverError) throw driverError;

    const driverId = driver.id;

    const documentTypes = {
      licenseFront: 'license_front',
      licenseBack: 'license_back',
      insurance: 'insurance',
      idDocument: 'id_document',
      vehiclePhoto: 'vehicle_photo',
    };

    for (const [key, type] of Object.entries(documentTypes)) {
      const base64 = documents?.[key];
      if (base64) {
        const url = await uploadDocument(driverId, type, base64);
        if (url) {
          await supabase.from('documents').insert([{
            driver_id: driverId,
            type: type,
            image_url: url,
            verified: false,
          }]);
        }
      }
    }

    res.json({ success: true, driverId: driverId });
  } catch (e) {
    console.error('❌ خطأ في طلب الشراكة:', e);
    res.status(500).json({ error: 'فشل إرسال الطلب' });
  }
});

// =====================================================
// 5. لوحة الإدارة (Admin)
// =====================================================

app.get('/api/admin/drivers/pending', async (req, res) => {
  const { data: drivers, error } = await supabase
    .from('drivers')
    .select('*, users(phone, name)')
    .eq('status', 'pending');

  if (error) return res.status(500).json({ error: 'فشل جلب الطلبات' });

  res.json(drivers);
});

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

app.post('/api/admin/wallets/charge', async (req, res) => {
  const { phone, amount } = req.body;
  if (!phone || !amount) return res.status(400).json({ error: 'بيانات ناقصة' });

  const { data: user } = await supabase
    .from('users')
    .select('id')
    .eq('phone', phone)
    .single();

  if (!user) return res.status(404).json({ error: 'السائق غير موجود' });

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

  await supabase.from('transactions').insert([{
    user_id: user.id,
    amount: parseFloat(amount),
    type: 'credit',
    reason: 'شحن رصيد من الإدارة'
  }]);

  res.json({ success: true, newBalance });
});

// =====================================================
// 6. Socket.IO
// =====================================================

const onlineUsers = new Map();

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
      console.error('❌ خطأ في حفظ الموقع:', e);
    }
  });

  socket.on('request:tow', async (data) => {
    try {
      const { driverId, vehicleType, pickup, dropoff, price } = data;

      const { data: request, error } = await supabase
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

      if (error) throw error;

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
      console.log(`📨 تم إرسال الطلب إلى ${sentCount} مزود`);
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
        .insert([{ request_id: requestId, driver_id: providerId, price }])
        .select()
        .single();

      if (error) throw error;

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
      console.log('💵 عرض سعر جديد:', offer.id);
    } catch (e) {
      console.error('❌ خطأ في إرسال العرض:', e);
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
