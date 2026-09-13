const express = require('express');
const router = express.Router();

const supabase = require('../config/supabase');
const asyncHandler = require('../utils/asyncHandler');

router.get('/', asyncHandler(async (req, res) => {
  const { data, error } = await supabase
    .from('workshops').select('*').order('rating', { ascending: false });
  if (error) throw error;
  res.json(data);
}));

module.exports = router;
