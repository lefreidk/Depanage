const { verifyToken } = require('../utils/jwt');

// يتحقق من وجود توكن JWT صالح في هيدر Authorization، ويرفض الطلب
// فوراً إذا كان مفقوداً أو غير صالح. هذا الوسيط يجب أن يُطبَّق على
// كل مسار لا يجب أن يكون عاماً بالكامل (خصوصاً كل /api/admin/*).
function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;

  if (!token) {
    return res.status(401).json({ error: 'المصادقة مطلوبة' });
  }

  try {
    const payload = verifyToken(token);
    req.user = payload; // { userId, phone, role }
    next();
  } catch (e) {
    return res.status(401).json({ error: 'الجلسة غير صالحة أو منتهية' });
  }
}

// يجب استخدامه بعد requireAuth — يتحقق أن دور المستخدم من ضمن
// الأدوار المسموح لها بالوصول لهذا المسار.
function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return res.status(403).json({ error: 'لا تملك صلاحية الوصول لهذا المورد' });
    }
    next();
  };
}

module.exports = { requireAuth, requireRole };
