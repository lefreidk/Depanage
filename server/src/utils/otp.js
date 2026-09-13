const env = require('../config/env');

function generateOtp() {
  return Math.floor(1000 + Math.random() * 9000).toString();
}

function cleanPhone(phone) {
  return (phone || '').replace(/[^0-9]/g, '');
}

async function sendWhatsAppOtp(phone, otp) {
  try {
    const phoneDigits = cleanPhone(phone);
    const url = `https://7107.api.greenapi.com/waInstance${env.greenApiId}/SendMessage/${env.greenApiToken}`;
    const body = {
      chatId: `${phoneDigits}@c.us`,
      message: `رمز التحقق الخاص بك في ديباناج هو: ${otp}\nصالح لمدة 10 دقائق. لا تشاركه مع أي شخص.`,
    };

    const res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });

    return res.ok;
  } catch (e) {
    console.error('❌ خطأ في إرسال واتساب:', e);
    return false;
  }
}

module.exports = { generateOtp, cleanPhone, sendWhatsAppOtp };
