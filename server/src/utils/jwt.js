const jwt = require('jsonwebtoken');
const env = require('../config/env');

// إصدار توكن جلسة لمستخدم مصادَق عليه (عميل/سائق/إدارة).
function signToken(payload) {
  return jwt.sign(payload, env.jwtSecret, { expiresIn: env.jwtExpiresIn });
}

function verifyToken(token) {
  return jwt.verify(token, env.jwtSecret);
}

module.exports = { signToken, verifyToken };
