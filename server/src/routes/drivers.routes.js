const express = require('express');
const router = express.Router();

const supabase = require('../config/supabase');
const asyncHandler = require('../utils/asyncHandler');
const { requireAuth } = require('../middleware/auth');

const ALLOWED_IMAGE_TYPES = ['image/png', 'image/jpeg', 'image/jpg', 'image/webp'];
const MAX_IMAGE_BYTES = 4 * 1024 * 1024; // 4MB لكل صورة

function decodeImage(base64String) {
  if (!base64String) return null;
  const match = /^data:(image\/\w+);base64,(.+)$/.exec(base64String);
  const mime = match ? match[1] : 'image/png';
  const raw = match ? match[2] : base64String;

  if (!ALLOWED_IMAGE_TYPES.includes(mime)) return null;

  const buffer = Buffer.from(raw, 'base64');
  if (buffer.length > MAX_IMAGE_BYTES) return null;

  return { buffer, mime };
}

async function uploadDocument(driverId, type, base64String) {
  const decoded = decodeImage(base64String);
  if (!decoded) return null;

  const ext = decoded.mime.split('/')[1];
  const fileName = `${driverId}/${type}_${Date.now()}.${ext}`;

  const { error } = await supabase.storage
    .from('documents')
    .upload(fileName, decoded.buffer, { contentType: decoded.mime, upsert: false });

  if (error) {
    console.error('❌ فشل رفع الوثيقة:', error);
    return null;
  }

  const { data } = supabase.storage.from('documents').getPublicUrl(fileName);
  return data.publicUrl;
}

// طلب الشراكة كسائق — يتطلب تسجيل دخول (userId من التوكن وليس من الجسم)
router.post('/apply', requireAuth, asyncHandler(async (req, res) => {
  const {
    fullName, licenseNumber, licenseExpiry,
    plateNumber, vehicleYear, vehicleTypes, documents,
  } = req.body;

  if (!fullName || !licenseNumber || !plateNumber || !Array.isArray(vehicleTypes) || vehicleTypes.length === 0) {
    return res.status(400).json({ error: 'بيانات السائق ناقصة' });
  }

  const userId = req.user.userId;

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
      status: 'pending',
    }])
    .select()
    .single();

  if (driverError) throw driverError;

  const documentTypes = {
    licenseFront: 'license_front',
    licenseBack: 'license_back',
    insurance: 'insurance',
    idDocument: 'id_document',
    vehiclePhoto: 'vehicle_photo',
  };

  for (const [key, type] of Object.entries(documentTypes)) {
    const base64 = documents?.[key];
    if (!base64) continue;

    const url = await uploadDocument(driver.id, type, base64);
    if (url) {
      await supabase.from('documents').insert([{
        driver_id: driver.id, type, image_url: url, verified: false,
      }]);
    }
  }

  res.json({ success: true, driverId: driver.id });
}));

module.exports = router;
