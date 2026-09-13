// معالج أخطاء مركزي — يُوضع كآخر middleware في التطبيق.
// يمنع تسرّب تفاصيل الأخطاء الداخلية (stack traces, رسائل DB) للعميل.
function errorHandler(err, req, res, next) {
  console.error('❌ خطأ غير متوقع:', err);

  if (res.headersSent) return next(err);

  res.status(err.statusCode || 500).json({
    error: err.publicMessage || 'حدث خطأ غير متوقع في الخادم',
  });
}

function notFoundHandler(req, res) {
  res.status(404).json({ error: 'المسار غير موجود' });
}

module.exports = { errorHandler, notFoundHandler };
