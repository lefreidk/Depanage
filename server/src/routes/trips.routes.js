const express = require('express');
const router = express.Router();

const supabase = require('../config/supabase');
const asyncHandler = require('../utils/asyncHandler');
const { requireAuth } = require('../middleware/auth');

router.use(requireAuth);

// حفظ تقييم رحلة مكتملة — كان يُحذف محلياً في النسخة السابقة بدل حفظه
router.post('/:tripId/rate', asyncHandler(async (req, res) => {
  const { tripId } = req.params;
  const { rating, tags } = req.body;

  if (!rating || rating < 1 || rating > 5) {
    return res.status(400).json({ error: 'التقييم يجب أن يكون بين 1 و 5' });
  }

  const { data: trip } = await supabase
    .from('trips').select('id, client_id').eq('id', tripId).single();

  if (!trip || trip.client_id !== req.user.userId) {
    return res.status(403).json({ error: 'لا يمكنك تقييم هذه الرحلة' });
  }

  const { error } = await supabase.from('ratings').insert([{
    trip_id: tripId,
    rating,
    tags: tags || [],
  }]);
  if (error) throw error;

  await supabase.from('trips').update({ rating }).eq('id', tripId);

  res.json({ success: true });
}));

module.exports = router;
