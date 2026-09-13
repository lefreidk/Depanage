require('dotenv').config();

// تحميل كل متغيرات البيئة من مكان واحد مع التحقق من وجود المطلوب منها
// بدل الاعتماد على process.env مباشرة في كل ملف.
const required = [
  'SUPABASE_URL',
  'SUPABASE_ANON_KEY',
  'UPSTASH_REDIS_URL',
  'UPSTASH_REDIS_TOKEN',
  'JWT_SECRET',
];

for (const key of required) {
  if (!process.env[key]) {
    console.error(`❌ متغير البيئة المطلوب مفقود: ${key}`);
    process.exit(1);
  }
}

module.exports = {
  port: process.env.PORT || 3000,
  supabaseUrl: process.env.SUPABASE_URL,
  supabaseKey: process.env.SUPABASE_ANON_KEY,
  redisUrl: process.env.UPSTASH_REDIS_URL,
  redisToken: process.env.UPSTASH_REDIS_TOKEN,
  jwtSecret: process.env.JWT_SECRET,
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '30d',
  greenApiId: process.env.GREEN_API_ID_INSTANCE,
  greenApiToken: process.env.GREEN_API_API_TOKEN_INSTANCE,
  corsOrigins: (process.env.CORS_ORIGINS || '').split(',').filter(Boolean),
  adminBcryptHash: process.env.ADMIN_PASSWORD_HASH, // كلمة مرور مُشفّرة، وليست نصاً عادياً
  adminUsername: process.env.ADMIN_USERNAME,
};
