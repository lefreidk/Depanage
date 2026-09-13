// يغلّف أي معالج Express غير متزامن حتى لا نضطر لكتابة try/catch
// في كل نقطة نهاية على حدة — أي خطأ يُمرَّر تلقائياً إلى errorHandler المركزي.
function asyncHandler(fn) {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

module.exports = asyncHandler;
