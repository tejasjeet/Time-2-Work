const express = require('express');
const { z } = require('zod');
const { Payment } = require('../models');
const { requireAuth } = require('../middleware/auth');
const { validateBody } = require('../middleware/validate');
const { AppError, asyncHandler } = require('../utils/errors');
const { paymentDto } = require('../utils/serializers');
const { env } = require('../config/env');
const { verifyWebhookSignature } = require('../utils/razorpay');
const { createOrder, markPaid, confirmByOrderId } = require('../services/payments');

const router = express.Router();

router.post(
  '/create-order',
  requireAuth,
  validateBody(
    z.object({
      type: z.enum(['job_fee', 'job_payout']),
      jobId: z.string().min(1),
      method: z.enum(['mock', 'razorpay']).optional(),
    })
  ),
  asyncHandler(async (req, res) => {
    const payment = await createOrder({
      userId: req.user.id,
      type: req.body.type,
      jobId: req.body.jobId,
      method: req.body.method,
    });
    res.status(201).json({
      payment: paymentDto(payment),
      razorpayKeyId: payment.method === 'razorpay' ? env.razorpayKeyId : undefined,
    });
  })
);

router.post(
  '/mock-confirm',
  requireAuth,
  validateBody(z.object({ orderId: z.string().min(1) })),
  asyncHandler(async (req, res) => {
    const payment = await Payment.findOne({ orderId: req.body.orderId });
    if (!payment) throw new AppError(404, 'Order not found');
    if (String(payment.userId) !== req.user.id && req.user.role !== 'admin') {
      throw new AppError(403, 'Not your order');
    }
    if (payment.method !== 'mock' && env.paymentsMode !== 'mock') {
      throw new AppError(400, 'Use Razorpay webhook for this order');
    }
    const updated = await confirmByOrderId(req.body.orderId);
    res.json({ payment: paymentDto(updated) });
  })
);

async function handleRazorpayWebhook(req, res) {
  const signature = req.headers['x-razorpay-signature'];
  const raw = Buffer.isBuffer(req.body) ? req.body : Buffer.from(JSON.stringify(req.body || {}));
  if (env.isProd || env.razorpayWebhookSecret) {
    if (!signature || !verifyWebhookSignature(raw, signature)) {
      throw new AppError(400, 'Invalid webhook signature');
    }
  }
  const event = Buffer.isBuffer(req.body) ? JSON.parse(req.body.toString('utf8')) : req.body;
  const entity = event?.payload?.payment?.entity || event?.payload?.order?.entity;
  const rzOrderId = entity?.order_id || entity?.id;
  const rzPaymentId = event?.payload?.payment?.entity?.id;
  if (!rzOrderId) return res.json({ ok: true, ignored: true });
  const payment = await Payment.findOne({ razorpayOrderId: rzOrderId });
  if (!payment) return res.json({ ok: true, ignored: true });
  if (event.event === 'payment.failed') {
    payment.status = 'failed';
    payment.razorpayPaymentId = rzPaymentId || payment.razorpayPaymentId;
    await payment.save();
    return res.json({ ok: true });
  }
  payment.razorpayPaymentId = rzPaymentId || payment.razorpayPaymentId;
  await markPaid(payment);
  res.json({ ok: true });
}

module.exports = router;
module.exports.handleRazorpayWebhook = handleRazorpayWebhook;
