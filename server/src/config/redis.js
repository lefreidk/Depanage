const { Redis } = require('@upstash/redis');
const env = require('./env');

const redis = new Redis({
  url: env.redisUrl,
  token: env.redisToken,
});

module.exports = redis;
