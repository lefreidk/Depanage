require('dotenv').config();
process.on('uncaughtException', (err) => {
  console.error('❌ خطأ غير متوقع:', err);
});

process.on('unhandledRejection', (reason) => {
  console.error('❌ وعد مرفوض غير معالج:', reason);
});
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');
const { Redis } = require('@upstash/redis');

const app = express();
app.use(cors());
app.use(express.json());

const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*' } });

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);
const redis = new Redis({
  url: process.env.UPSTASH_REDIS_URL,
  token: process.env.UPSTASH_REDIS_TOKEN,
});

const GREEN_API_ID = process.env.GREEN_API_ID_INSTANCE;
const GREEN_API_TOKEN = process.env.GREEN_API_API_TOKEN_INSTANCE;

async function sendWhatsAppOtp(phone, otp) {
  const url = `https://7107.api.greenapi.com/waInstance${GREEN_API_ID}/SendMessage/${GREEN_API_TOKEN}`;
  const body = {
    chatId: `${phone}@c.us`,
    message: `رمز التحقق الخاص بك هو: ${otp}`
  };
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  });
  return res.ok;
}

function generateOtp() {
  return Math.floor(1000 + Math.random() * 9000).toString();
}

app.get('/', (req, res) => res.send('ديباناج يعمل! 🚛'));

app.post('/api/auth/send-otp', async (req, res) => {
  const { phone } = req.body;
  if (!phone) return res.status(400).json({ error: 'رقم الهاتف مطلوب' });
  const otp = generateOtp();
  await redis.set(`otp:${phone}`, otp, { ex: 300 });
  const sent = await sendWhatsAppOtp(phone, otp);
  if (sent) res.json({ success: true });
  else res.status(500).json({ error: 'فشل إرسال الرمز' });
});

app.post('/api/auth/verify-otp', async (req, res) => {
  const { phone, otp } = req.body;
  const stored = await redis.get(`otp:${phone}`);
  if (stored === otp) {
    await redis.del(`otp:${phone}`);
    res.json({ success: true, userId: phone, phone });
  } else {
    res.status(400).json({ error: 'رمز التحقق غير صحيح' });
  }
});

// ... باقي أحداث Socket.IO كما كانت سابقًا
// (أدرجها هنا من النسخة السابقة)
