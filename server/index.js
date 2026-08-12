// --- تحميل المكتبات ---
require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');
const { Redis } = require('@upstash/redis');

// --- إعداد Express و Socket.IO ---
const app = express();
app.use(cors());
app.use(express.json());

const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*' }
});

// --- الاتصال بـ Supabase ---
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

// --- الاتصال بـ Upstash Redis (مع الرمز) ---
const redis = new Redis({
  url: process.env.UPSTASH_REDIS_URL,
  token: process.env.UPSTASH_REDIS_TOKEN,
});

// --- نقطة فحص ---
app.get('/', (req, res) => {
  res.send('ديباناج يعمل! 🚛');
});

// --- خريطة المستخدمين المتصلين ---
const onlineUsers = new Map(); // userId → socketId

// --- أحداث Socket.IO ---
io.on('connection', (socket) => {
  console.log('👤 متصل:', socket.id);

  // تسجيل المستخدم
  socket.on('register', (userId) => {
    onlineUsers.set(userId.toString(), socket.id);
    socket.userId = userId;
    console.log(`✅ مستخدم ${userId} مسجل`);
  });

  // مزوّد الخدمة يُرسل موقعه الحي
  socket.on('provider:location', async (data) => {
    const { userId, lat, lng } = data;
    await redis.geoadd('providers:locations', {
      longitude: lng,
      latitude: lat,
      member: userId.toString()
    });
  });

  // سائق ينشئ طلب ونش
  socket.on('request:tow', async (data) => {
    const { driverId, vehicleType, pickup, dropoff, price } = data;

    // 1. حفظ الطلب في Supabase
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

    if (error) {
      console.error('❌ خطأ في حفظ الطلب:', error);
      socket.emit('error', { message: 'فشل إنشاء الطلب' });
      return;
    }

    const requestId = request.id;

    // 2. البحث عن أقرب 5 مزودين في نطاق 50 كم
    const nearbyProviders = await redis.geosearch(
      'providers:locations',
      { longitude: pickup.lng, latitude: pickup.lat },
      { radius: 50, unit: 'km', count: 5, withDistances: true }
    );

    // 3. إرسال الطلب لكل مزود قريب متصل
    let sentCount = 0;
    for (const provider of nearbyProviders) {
      const providerId = provider.member;
      const providerSocketId = onlineUsers.get(providerId);
      if (providerSocketId) {
        io.to(providerSocketId).emit('new:request', {
          requestId,
          vehicleType,
          pickup,
          dropoff,
          price,
          distance: provider.distance
        });
        sentCount++;
      }
    }

    // 4. إشعار السائق
    socket.emit('request:created', { requestId, nearbyCount: sentCount });
  });

  // مزوّد يُرسل عرض سعر
  socket.on('offer:make', async (data) => {
    const { requestId, providerId, price } = data;

    const { data: offer, error } = await supabase
      .from('offers')
      .insert([{ request_id: requestId, provider_id: providerId, price: price }])
      .select()
      .single();

    if (error) {
      console.error('❌ خطأ في حفظ العرض:', error);
      return;
    }

    // جلب السائق صاحب الطلب
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
  });

  // سائق يقبل عرضًا
  socket.on('offer:accept', async (data) => {
    const { offerId, requestId, providerId } = data;

    await supabase.from('offers').update({ status: 'accepted' }).eq('id', offerId);
    await supabase.from('tow_requests').update({ status: 'accepted', provider_id: providerId }).eq('id', requestId);

    const providerSocketId = onlineUsers.get(providerId.toString());
    if (providerSocketId) {
      io.to(providerSocketId).emit('offer:accepted', { requestId });
    }
  });

  // قطع الاتصال
  socket.on('disconnect', () => {
    if (socket.userId) {
      onlineUsers.delete(socket.userId.toString());
      console.log(`👋 مستخدم ${socket.userId} غادر`);
    }
  });
});

// --- تشغيل الخادم ---
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`🚀 خادم ديباناج يعمل على المنفذ ${PORT}`);
});
