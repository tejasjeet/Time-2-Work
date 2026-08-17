const { env } = require('../config/env');

let client = null;

function getRazorpay() {
  if (env.paymentsMode !== 'razorpay' && !env.razorpayKeyId) return null;
  if (client) return client;
  if (!env.razorpayKeyId || !env.razorpayKeySecret) return null;
  const Razorpay = require('razorpay');
  client = new Razorpay({
    key_id: env.razorpayKeyId,
    key_secret: env.razorpayKeySecret,
  });
  return client;
}

function verifyWebhookSignature(rawBody, signature) {
  const crypto = require('crypto');
  const expected = crypto
    .createHmac('sha256', env.razorpayWebhookSecret)
    .update(rawBody)
    .digest('hex');
  return expected === signature;
}

module.exports = { getRazorpay, verifyWebhookSignature };
