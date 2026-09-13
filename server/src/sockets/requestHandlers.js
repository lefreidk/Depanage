const supabase = require('../config/supabase');
const redis = require('../config/redis');
const onlineUsers = require('./onlineUsers');

const NEARBY_RADIUS_KM = 20;

// يبحث عن السائقين المعتمدين والمتصلين حالياً ضمن نطاق جغرافي معين
// حول نقطة الانطلاق، بدل بث الطلب لكل من هو متصل بالتطبيق.
async function findNearbyApprovedDrivers(pickup, vehicleCategory) {
  let nearbyIds = [];
  try {
    const results = await redis.geosearch('providers:locations', {
      type: 'fromlonlat',
      coordinate: { lon: pickup.lng, lat: pickup.lat },
      radius: NEARBY_RADIUS_KM,
      radiusType: 'km',
    });
    nearbyIds = (results || []).map((r) => (typeof r === 'string' ? r : r.member));
  } catch (e) {
    console.error('⚠️ تعذر البحث الجغرافي عن السائقين، سيتم التراجع لكل السائقين المتصلين:', e.message);
  }

  if (nearbyIds.length === 0) {
    // تراجع آمن: لو فشل البحث الجغرافي (مثلاً لا يوجد سائقون سجّلوا موقعهم بعد)
    // نستخدم كل السائقين المتصلين حالياً بدل عدم إرسال أي شيء.
    nearbyIds = Array.from(onlineUsers.keys());
  }

  if (nearbyIds.length === 0) return [];

  const { data: drivers, error } = await supabase
    .from('drivers')
    .select('user_id, vehicle_types, status')
    .in('user_id', nearbyIds)
    .eq('status', 'approved');

  if (error) {
    console.error('❌ خطأ في جلب السائقين المعتمدين:', error);
    return [];
  }

  return drivers
    .filter((d) => !vehicleCategory || (d.vehicle_types || []).includes(vehicleCategory))
    .map((d) => d.user_id.toString());
}

function registerRequestHandlers(io, socket) {
  socket.on('provider:location', async (data) => {
    try {
      const { lat, lng } = data;
      const userId = socket.user.userId.toString();

      await redis.geoadd('providers:locations', { longitude: lng, latitude: lat, member: userId });

      // إذا كان هذا السائق مرتبطاً برحلة نشطة، نبثّ موقعه فوراً للعميل
      // صاحب تلك الرحلة (هذا ما كان مفقوداً بالكامل في النسخة السابقة).
      const { data: activeRequest } = await supabase
        .from('tow_requests')
        .select('id, client_id')
        .eq('provider_id', userId)
        .in('status', ['accepted', 'in_progress'])
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle();

      if (activeRequest) {
        const clientSocketId = onlineUsers.get(activeRequest.client_id.toString());
        if (clientSocketId) {
          io.to(clientSocketId).emit('provider:location:update', {
            requestId: activeRequest.id,
            lat,
            lng,
          });
        }
      }
    } catch (e) {
      console.error('❌ خطأ في تحديث الموقع:', e);
    }
  });

  socket.on('request:tow', async (data) => {
    try {
      if (socket.user.role !== 'client') {
        return socket.emit('error', { message: 'غير مصرح بإنشاء طلب' });
      }

      const { vehicleType, pickup, dropoff, price } = data;
      const clientId = socket.user.userId;

      const { data: request, error } = await supabase
        .from('tow_requests')
        .insert([{
          client_id: clientId,
          vehicle_category: vehicleType,
          pickup_lat: pickup.lat,
          pickup_lng: pickup.lng,
          dropoff_lat: dropoff.lat,
          dropoff_lng: dropoff.lng,
          price,
          status: 'pending',
        }])
        .select()
        .single();

      if (error) throw error;

      const nearbyDriverIds = await findNearbyApprovedDrivers(pickup, vehicleType);

      let sentCount = 0;
      for (const driverId of nearbyDriverIds) {
        const socketId = onlineUsers.get(driverId);
        if (socketId) {
          io.to(socketId).emit('new:request', {
            requestId: request.id,
            vehicleType,
            pickup,
            dropoff,
            price,
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

  socket.on('offer:make', async (data) => {
    try {
      if (socket.user.role !== 'driver' && socket.user.role !== 'client') {
        // السماح مبدئياً لأي مستخدم مصادَق لتوافق النسخة الحالية من الأدوار،
        // لكن يُفضّل حصر هذا صراحة بدور 'driver' بعد تفعيل الأدوار الكاملة.
      }

      const { requestId, price } = data;
      const providerId = socket.user.userId;

      const { data: offer, error } = await supabase
        .from('offers')
        .insert([{ request_id: requestId, driver_id: providerId, price }])
        .select()
        .single();
      if (error) throw error;

      const { data: request } = await supabase
        .from('tow_requests').select('client_id').eq('id', requestId).single();

      const clientSocketId = onlineUsers.get(request.client_id.toString());
      if (clientSocketId) {
        io.to(clientSocketId).emit('new:offer', {
          offerId: offer.id,
          requestId,
          providerId,
          price,
        });
      }
    } catch (e) {
      console.error('❌ خطأ في إرسال العرض:', e);
    }
  });

  socket.on('offer:accept', async (data) => {
    try {
      const { offerId, requestId, providerId } = data;

      await supabase.from('offers').update({ status: 'accepted' }).eq('id', offerId);
      await supabase
        .from('tow_requests')
        .update({ status: 'accepted', provider_id: providerId })
        .eq('id', requestId);

      const providerSocketId = onlineUsers.get(providerId.toString());
      if (providerSocketId) {
        io.to(providerSocketId).emit('offer:accepted', { requestId });
      }
    } catch (e) {
      console.error('❌ خطأ في قبول العرض:', e);
    }
  });

  // إنهاء الرحلة من جهة السائق فقط + خصم العمولة فعلياً
  socket.on('trip:complete', async (data) => {
    try {
      const { requestId } = data;
      const providerId = socket.user.userId;

      const { data: request, error } = await supabase
        .from('tow_requests')
        .select('*')
        .eq('id', requestId)
        .eq('provider_id', providerId)
        .single();

      if (error || !request) {
        return socket.emit('error', { message: 'الرحلة غير موجودة أو لا تخصك' });
      }

      await supabase.from('tow_requests').update({ status: 'completed' }).eq('id', requestId);

      const { data: trip, error: tripError } = await supabase
        .from('trips')
        .insert([{
          request_id: requestId,
          driver_id: providerId,
          client_id: request.client_id,
          vehicle_category: request.vehicle_category,
          pickup_lat: request.pickup_lat,
          pickup_lng: request.pickup_lng,
          dropoff_lat: request.dropoff_lat,
          dropoff_lng: request.dropoff_lng,
          final_price: request.price,
          status: 'completed',
          completed_at: new Date().toISOString(),
        }])
        .select()
        .single();

      if (tripError) throw tripError;

      // خصم العمولة من رصيد السائق بناءً على الإعدادات الفعلية
      const { data: settingsRow } = await supabase
        .from('app_settings').select('value').eq('key', 'commission_rate').maybeSingle();
      const commissionRate = Number(settingsRow?.value ?? 15) / 100;
      const commissionAmount = Math.round(request.price * commissionRate);

      const { data: wallet } = await supabase
        .from('wallets').select('balance').eq('user_id', providerId).maybeSingle();
      const newBalance = (wallet?.balance || 0) - commissionAmount;

      await supabase.from('wallets').upsert({ user_id: providerId, balance: newBalance });
      await supabase.from('transactions').insert([{
        user_id: providerId,
        amount: commissionAmount,
        type: 'debit',
        reason: `عمولة رحلة #${requestId}`,
      }]);

      const clientSocketId = onlineUsers.get(request.client_id.toString());
      if (clientSocketId) {
        io.to(clientSocketId).emit('trip:completed', { requestId, tripId: trip.id });
      }

      socket.emit('trip:completed', { requestId, tripId: trip.id, commissionAmount, newBalance });
    } catch (e) {
      console.error('❌ خطأ في إنهاء الرحلة:', e);
      socket.emit('error', { message: 'فشل إنهاء الرحلة' });
    }
  });
}

module.exports = { registerRequestHandlers };
