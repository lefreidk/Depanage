const express = require('express');
const router = express.Router();

const supabase = require('../config/supabase');
const asyncHandler = require('../utils/asyncHandler');
const { requireAuth } = require('../middleware/auth');

router.use(requireAuth);

// سجل طلبات المستخدم الحالي (مأخوذ من التوكن، وليس من query parameter يمكن التلاعب به)
router.get('/history', asyncHandler(async (req, res) => {
  const { data, error } = await supabase
    .from('tow_requests')
    .select('*')
    .eq('client_id', req.user.userId)
    .order('created_at', { ascending: false })
    .limit(50);

  if (error) throw error;

  res.json(data.map((r) => ({
    id: r.id,
    vehicleCategory: r.vehicle_category,
    pickupLat: r.pickup_lat,
    pickupLng: r.pickup_lng,
    dropoffLat: r.dropoff_lat,
    dropoffLng: r.dropoff_lng,
    price: r.price,
    status: r.status,
    createdAt: r.created_at,
  })));
}));

module.exports = router;
