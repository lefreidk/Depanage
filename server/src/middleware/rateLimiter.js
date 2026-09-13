const redis = require('../config/redis');
const { cleanPhone } = require('../utils/otp');

// يحدّ من عدد مرات طلب OTP لكل رقم هاتف: طلب واحد كل 60 ثانية،
// وحد أقصى 5 طلبات خلال ساعة. يمنع استنزاف رصيد Green API
// ورسائل السبام عبر واتساب.
function otpSendLimiter() {
  return async (req, res, next) => {
    const phone = cleanPhone(req.body?.phone);
    if (!phone) return res.status(400).json({ error: 'رقم الهاتف مطلوب' });

    const cooldownKey = `otp_cooldown:${phone}`;
    const hourlyKey = `otp_hourly:${phone}`;

    const inCooldown = await redis.get(cooldownKey);
    if (inCooldown) {
      return res.status(429).json({ error: 'الرجاء الانتظار قليلاً قبل طلب رمز جديد' });
    }

    const hourlyCount = (await redis.get(hourlyKey)) || 0;
    if (Number(hourlyCount) >= 5) {
      return res.status(429).json({ error: 'تم تجاوز الحد المسموح من المحاولات، حاول لاحقاً' });
    }

    await redis.set(cooldownKey, '1', { ex: 60 });
    await redis.set(hourlyKey, Number(hourlyCount) + 1, { ex: 3600 });

    next();
  };
}

// يحدّ من عدد محاولات إدخال رمز OTP الخاطئ لكل رقم — يمنع الهجوم
// بالقوة الغاشمة على فضاء 4 أرقام خلال مدة صلاحية الرمز.
function otpVerifyLimiter() {
  return async (req, res, next) => {
    const phone = cleanPhone(req.body?.phone);
    if (!phone) return res.status(400).json({ error: 'رقم الهاتف مطلوب' });

    const attemptsKey = `otp_attempts:${phone}`;
    const attempts = (await redis.get(attemptsKey)) || 0;

    if (Number(attempts) >= 5) {
      return res.status(429).json({ error: 'تم تجاوز عدد المحاولات المسموح، اطلب رمزاً جديداً' });
    }

    req._otpAttemptsKey = attemptsKey;
    req._otpAttemptsCount = Number(attempts);
    next();
  };
}

// محدد عام لمحاولات تسجيل الدخول (مثل دخول الإدارة)، يعمل حسب أي
// مفتاح تعريفي (اسم مستخدم أو عنوان IP) بدل رقم الهاتف تحديداً.
function loginAttemptLimiter({ maxAttempts = 5, windowSeconds = 900 } = {}) {
  return async (req, res, next) => {
    const key = `login_attempts:${req.body?.username || req.ip}`;
    const attempts = Number((await redis.get(key)) || 0);

    if (attempts >= maxAttempts) {
      return res.status(429).json({ error: 'تم تجاوز عدد المحاولات المسموح، حاول لاحقاً' });
    }

    req._loginAttemptsKey = key;
    req._loginAttemptsCount = attempts;
    next();
  };
}

// يُستدعى بعد فشل محاولة تسجيل الدخول لزيادة العداد.
async function registerFailedLogin(req) {
  if (!req._loginAttemptsKey) return;
  await redis.set(req._loginAttemptsKey, req._loginAttemptsCount + 1, { ex: 900 });
}

module.exports = { otpSendLimiter, otpVerifyLimiter, loginAttemptLimiter, registerFailedLogin };
