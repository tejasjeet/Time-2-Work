const express = require('express');
const { z } = require('zod');
const { Report } = require('../models');
const { requireAuth } = require('../middleware/auth');
const { validateBody } = require('../middleware/validate');
const { asyncHandler } = require('../utils/errors');
const { notifyUser } = require('../utils/notify');

const router = express.Router();

router.post(
  '/',
  requireAuth,
  validateBody(
    z.object({
      lat: z.coerce.number(),
      lng: z.coerce.number(),
      contactName: z.string().min(1),
      contactPhone: z.string().min(8),
    })
  ),
  asyncHandler(async (req, res) => {
    const { lat, lng, contactName, contactPhone } = req.body;
    const report = await Report.create({
      reporterId: req.user.id,
      targetType: 'sos',
      reason: 'sos',
      details: JSON.stringify({ lat, lng, contactName, contactPhone }),
      status: 'open',
    });
    console.log(`[SOS] user=${req.user.id} lat=${lat} lng=${lng} contact=${contactName}`);
    await notifyUser(req.user.id, {
      title: 'SOS recorded',
      body: `Emergency alert saved. ${contactName} will be notified.`,
      type: 'sos',
      data: { reportId: String(report._id) },
    });
    res.status(201).json({
      ok: true,
      id: String(report._id),
      message: 'SOS recorded. Emergency contact will be notified.',
    });
  })
);

module.exports = router;
