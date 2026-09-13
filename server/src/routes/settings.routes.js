const express = require('express');
const router = express.Router();

const supabase = require('../config/supabase');
const asyncHandler = require('../utils/asyncHandler');

// نقطة عامة (بدون مصادقة) تُعيد إعدادات التسعير/العمولة الحالية
// حتى يستهلكها التطبيق فعلياً بدل الاعتماد على قيم ثابتة في الكود،
// وحتى تصبح شاشة إعدادات الإدارة ذات أثر حقيقي.
router.get('/', asyncHandler(async (req, res) => {
  const { data, error } = await supabase.from('app_settings').select('key, value');
  if (error) throw error;

  const settings = Object.fromEntries((data || []).map((row) => [row.key, row.value]));

  res.json({
    commissionRate: Number(settings.commission_rate ?? 15),
    minWalletBalance: Number(settings.min_wallet_balance ?? 500),
    pricePerKm: {
      motorcycle: Number(settings.price_per_km_motorcycle ?? 300),
      car: Number(settings.price_per_km_car ?? 500),
      utility: Number(settings.price_per_km_car ?? 500),
      truck: Number(settings.price_per_km_truck ?? 900),
      heavy_truck: Number(settings.price_per_km_truck ?? 900),
    },
  });
}));

module.exports = router;
