const express = require('express');
const router = express.Router();

router.use('/auth', require('./auth.routes'));
router.use('/admin', require('./admin.routes'));
router.use('/drivers', require('./drivers.routes'));
router.use('/requests', require('./requests.routes'));
router.use('/workshops', require('./workshops.routes'));
router.use('/settings', require('./settings.routes'));
router.use('/trips', require('./trips.routes'));
router.use('/users', require('./users.routes'));

module.exports = router;
