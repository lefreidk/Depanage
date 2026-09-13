const express = require('express');
const cors = require('cors');
const env = require('./config/env');
const routes = require('./routes');
const { errorHandler, notFoundHandler } = require('./middleware/errorHandler');

const app = express();

// CORS مقيّد بقائمة نطاقات محددة بدل '*' — يُضبط عبر CORS_ORIGINS في env
app.use(cors({
  origin: env.corsOrigins.length > 0 ? env.corsOrigins : true,
}));

app.use(express.json({ limit: '8mb' }));

app.get('/', (req, res) => res.send('ديباناج يعمل 🚛'));

app.use('/api', routes);

app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;
