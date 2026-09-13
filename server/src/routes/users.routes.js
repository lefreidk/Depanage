const express = require('express');
const router = express.Router();

const supabase = require('../config/supabase');
const asyncHandler = require('../utils/asyncHandler');
const { requireAuth } = require('../middleware/auth');

router.use(requireAuth);

// إعادة بيانات المستخدم الحالي بناءً على هوية التوكن، وليس بارامتر قابل للتلاعب
router.get('/me', asyncHandler(async (req, res) => {
  const { data: user, error } = await supabase
    .from('users').select('id, phone, name, role, blocked').eq('id', req.user.userId).single();
  if (error) throw error;
  res.json(user);
}));

router.patch('/me', asyncHandler(async (req, res) => {
  const { name } = req.body;
  if (!name || !name.trim()) return res.status(400).json({ error: 'الاسم مطلوب' });

  const { error } = await supabase.from('users').update({ name: name.trim() }).eq('id', req.user.userId);
  if (error) throw error;
  res.json({ success: true });
}));

module.exports = router;
