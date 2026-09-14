# تنبيه مهم — اقرأ قبل الاستخدام

هذا المجلد (`android/`) أعدت بناءه نصياً من الملفات التي شاركتها معي سابقاً في
المحادثة. **لكنه ينقصه ملف واحد لا أستطيع توليده في بيئتي: `gradle/wrapper/gradle-wrapper.jar`**
(ملف ثنائي مضغوط، وليس نص عادي، ولا يوجد لدي اتصال إنترنت لتنزيله).

بدون هذا الملف، أمر `flutter build apk` سيفشل فوراً برسالة شبيهة بـ:
`Error: Could not find or load main class org.gradle.wrapper.GradleWrapperMain`

## الحل (اختر واحداً فقط):

### الخيار الأفضل والأسهل
إن كان مستودعك الأصلي على GitHub لا يزال يحتوي على مجلد `mobile/android` القديم،
**لا تستبدله بهذا المجلد إطلاقاً** — احتفظ بالأصلي كما هو (هو يحتوي فعلاً على
`gradle-wrapper.jar` صالح لأنه بُني وعمل سابقاً). استخدم من هذا الأرشيف فقط:
`mobile/lib`, `mobile/pubspec.yaml`, `mobile/assets`.

### إن لم يعد عندك النسخة الأصلية
شغّل هذا الأمر مرة واحدة على جهازك (يتطلب تثبيت Gradle محلياً أو استخدام
أي مشروع Flutter آخر عندك يعمل بنجاح):
```bash
cd mobile/android
gradle wrapper --gradle-version 8.12.1
```
سيولّد هذا الأمر ملف `gradle-wrapper.jar` الصحيح تلقائياً.

### بديل آخر
احذف مجلد `android/` بالكامل من هذا الأرشيف، ثم شغّل:
```bash
cd mobile
flutter create --platforms=android .
```
سيُعيد Flutter توليد مجلد `android/` كاملاً وصحيحاً من صفر (يتضمن الـ wrapper)،
وبعدها انسخ التعديلات اليدوية الموجودة في هذا المجلد (applicationId, الصلاحيات
في AndroidManifest.xml, إلخ) إلى النسخة المُولَّدة حديثاً.
