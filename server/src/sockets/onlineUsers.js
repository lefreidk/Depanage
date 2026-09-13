// خريطة بسيطة userId -> socketId. ملاحظة معروفة: هذه الخريطة في الذاكرة
// ولا تصمد أمام تعدد عمليات Node أو إعادة التشغيل. للتوسّع الأفقي
// لاحقاً يُفضّل نقلها إلى Redis (hash) بدل Map محلي.
const onlineUsers = new Map();

module.exports = onlineUsers;
