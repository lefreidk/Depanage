const express = require('express');
const router = express.Router();

const supabase = require('../config/supabase');
const asyncHandler = require('../utils/asyncHandler');
const { requireAuth, requireRole } = require('../middleware/auth');

// كل المسارات في هذا الملف تتطلب توكن صالح + دور admin
router.use(requireAuth, requireRole('admin'));

router.get('/stats', asyncHandler(async (req, res) => {
  const { count: activeTrips } = await supabase
    .from('trips').select('id', { count: 'exact', head: true }).eq('status', 'in_progress');

  const { count: completedTrips } = await supabase
    .from('trips').select('id', { count: 'exact', head: true }).eq('status', 'completed');

  const { data: drivers } = await supabase.from('drivers').select('id, status');
  const onlineDrivers = (drivers || []).filter((d) => d.status === 'approved').length;

  const { data: transactions } = await supabase.from('transactions').select('amount, type');
  const pendingRevenue = (transactions || [])
    .filter((t) => t.type === 'debit')
    .reduce((sum, t) => sum + parseFloat(t.amount || 0), 0);

  res.json({
    active_trips: activeTrips || 0,
    completed_trips: completedTrips || 0,
    online_drivers: onlineDrivers,
    pending_revenue: pendingRevenue,
  });
}));

router.get('/drivers/pending', asyncHandler(async (req, res) => {
  const { data, error } = await supabase
    .from('drivers').select('*, users(phone, name)').eq('status', 'pending');
  if (error) throw error;
  res.json(data);
}));

router.get('/drivers/approved', asyncHandler(async (req, res) => {
  const { data: drivers, error } = await supabase
    .from('drivers').select('*, users(phone, name)').eq('status', 'approved');
  if (error) throw error;

  const { data: wallets } = await supabase.from('wallets').select('user_id, balance');
  const walletMap = Object.fromEntries((wallets || []).map((w) => [w.user_id, w.balance]));

  res.json(drivers.map((d) => ({ ...d, wallet_balance: walletMap[d.user_id] || 0 })));
}));

router.post('/drivers/decision', asyncHandler(async (req, res) => {
  const { driverId, decision, reason } = req.body;
  if (!driverId || !['approve', 'reject'].includes(decision)) {
    return res.status(400).json({ error: 'بيانات غير صالحة' });
  }

  const newStatus = decision === 'approve' ? 'approved' : 'rejected';
  const { error } = await supabase
    .from('drivers')
    .update({ status: newStatus, rejection_reason: reason || null })
    .eq('id', driverId);

  if (error) throw error;
  res.json({ success: true });
}));

router.post('/wallets/charge', asyncHandler(async (req, res) => {
  const { phone, amount } = req.body;
  const numericAmount = parseFloat(amount);

  if (!phone || !numericAmount || numericAmount <= 0) {
    return res.status(400).json({ error: 'بيانات غير صالحة' });
  }

  const cleanedPhone = String(phone).replace(/[^0-9]/g, '');
  const { data: user } = await supabase.from('users').select('id').eq('phone', cleanedPhone).single();
  if (!user) return res.status(404).json({ error: 'المستخدم غير موجود' });

  const { data: wallet } = await supabase.from('wallets').select('balance').eq('user_id', user.id).single();
  const newBalance = (wallet?.balance || 0) + numericAmount;

  const { error: upsertError } = await supabase
    .from('wallets').upsert({ user_id: user.id, balance: newBalance });
  if (upsertError) throw upsertError;

  await supabase.from('transactions').insert([{
    user_id: user.id,
    amount: numericAmount,
    type: 'credit',
    reason: 'شحن رصيد من الإدارة',
  }]);

  res.json({ success: true, newBalance });
}));

router.get('/clients', asyncHandler(async (req, res) => {
  const { data, error } = await supabase
    .from('users').select('id, phone, name, blocked').eq('role', 'client')
    .order('created_at', { ascending: false });
  if (error) throw error;
  res.json(data);
}));

router.post('/clients/block', asyncHandler(async (req, res) => {
  const { userId, block } = req.body;
  if (!userId) return res.status(400).json({ error: 'معرف المستخدم مطلوب' });

  const { error } = await supabase.from('users').update({ blocked: !!block }).eq('id', userId);
  if (error) throw error;
  res.json({ success: true });
}));

router.post('/settings/update', asyncHandler(async (req, res) => {
  const {
    commission_rate, min_wallet_balance,
    price_per_km_motorcycle, price_per_km_car, price_per_km_truck,
  } = req.body;

  const settings = {
    commission_rate: String(commission_rate ?? 15),
    min_wallet_balance: String(min_wallet_balance ?? 500),
    price_per_km_motorcycle: String(price_per_km_motorcycle ?? 300),
    price_per_km_car: String(price_per_km_car ?? 500),
    price_per_km_truck: String(price_per_km_truck ?? 900),
  };

  for (const [key, value] of Object.entries(settings)) {
    const { error } = await supabase.from('app_settings').upsert({ key, value }, { onConflict: 'key' });
    if (error) throw error;
  }

  res.json({ success: true });
}));

module.exports = router;
