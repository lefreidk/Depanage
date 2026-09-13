const express = require('express');
const bcrypt = require('bcryptjs');
const router = express.Router();

const supabase = require('../config/supabase');
const redis = require('../config/redis');
const env = require('../config/env');
const asyncHandler = require('../utils/asyncHandler');
const { signToken } = require('../utils/jwt');
const { generateOtp, cleanPhone, sendWhatsAppOtp } = require('../utils/otp');
const { otpSendLimiter, otpVerifyLimiter, loginAttemptLimiter, registerFailedLogin } = require('../middleware/rateLimiter');

// إرسال رمز التحقق عبر واتساب (محدود بمعدل الطلبات)
router.post('/send-otp', otpSendLimiter(), asyncHandler(async (req, res) => {
  const phone = cleanPhone(req.body.phone);
  const otp = generateOtp();

  await redis.set(`otp:${phone}`, otp, { ex: 600 });
  await redis.del(`otp_attempts:${phone}`); // إعادة تعيين محاولات التحقق عند إصدار رمز جديد

  const sent = await sendWhatsAppOtp(phone, otp);
  if (!sent) return res.status(500).json({ error: 'فشل إرسال الرمز، حاول مجدداً' });

  res.json({ success: true, message: 'تم إرسال الرمز عبر واتساب' });
}));

// التحقق من الرمز وإصدار جلسة (JWT)
router.post('/verify-otp', otpVerifyLimiter(), asyncHandler(async (req, res) => {
  const phone = cleanPhone(req.body.phone);
  const otp = (req.body.otp || '').trim();

  const stored = await redis.get(`otp:${phone}`);

  if (String(stored || '') !== otp) {
    const attempts = req._otpAttemptsCount + 1;
    await redis.set(req._otpAttemptsKey, attempts, { ex: 600 });
    return res.status(400).json({ error: 'رمز التحقق غير صحيح' });
  }

  await redis.del(`otp:${phone}`);
  await redis.del(req._otpAttemptsKey);

  let { data: user } = await supabase.from('users').select('*').eq('phone', phone).single();

  if (!user) {
    const { data: newUser, error } = await supabase
      .from('users')
      .insert([{ phone, role: 'client' }])
      .select()
      .single();
    if (error) throw error;
    user = newUser;
  }

  // منع دخول المستخدمين المحظورين بدل الاكتفاء بحقل زخرفي في قاعدة البيانات
  if (user.blocked) {
    return res.status(403).json({ error: 'تم حظر هذا الحساب، تواصل مع الدعم الفني' });
  }

  const token = signToken({ userId: user.id, phone: user.phone, role: user.role });

  res.json({
    success: true,
    token,
    id: user.id,
    phone: user.phone,
    name: user.name || '',
    role: user.role,
    blocked: user.blocked || false,
  });
}));

// تسجيل دخول الإدارة — كلمة مرور مشفّرة + توكن حقيقي بدل بيانات ثابتة
router.post('/admin-login', loginAttemptLimiter(), asyncHandler(async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ error: 'بيانات الدخول مطلوبة' });
  }

  if (!env.adminUsername || !env.adminBcryptHash) {
    return res.status(500).json({ error: 'لم يتم إعداد حساب الإدارة على الخادم' });
  }

  if (username !== env.adminUsername) {
    await registerFailedLogin(req);
    return res.status(401).json({ error: 'بيانات الدخول غير صحيحة' });
  }

  const valid = await bcrypt.compare(password, env.adminBcryptHash);
  if (!valid) {
    await registerFailedLogin(req);
    return res.status(401).json({ error: 'بيانات الدخول غير صحيحة' });
  }

  const token = signToken({ userId: 'admin', phone: null, role: 'admin' });
  res.json({ success: true, token });
}));

module.exports = router;
