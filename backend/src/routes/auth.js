const express = require('express');
const bcrypt = require('bcryptjs');
const { z } = require('zod');
const rateLimit = require('express-rate-limit');
const { User, Otp, WorkerProfile, BusinessProfile } = require('../models');
const { env } = require('../config/env');
const { AppError, asyncHandler } = require('../utils/errors');
const { normalizePhone, isValidIndianPhone } = require('../utils/phone');
const { issueUserTokens, hashToken, verifyRefreshToken } = require('../utils/jwt');
const { meUser } = require('../utils/serializers');
const { requireAuth } = require('../middleware/auth');
const { validateBody } = require('../middleware/validate');
const { verifyFirebaseIdToken } = require('../utils/firebase');

const router = express.Router();

const otpLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: env.isProd ? 5 : 100,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => `otp:${normalizePhone(req.body?.phone || req.ip || 'unknown')}`,
  message: { error: { message: 'Too many OTP requests. Try again later.', code: 'RATE_LIMIT' } },
});

const verifyLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: { message: 'Too many verify attempts.', code: 'RATE_LIMIT' } },
});

const sendOtpSchema = z.object({
  phone: z.string().min(10),
});

const verifyOtpSchema = z.object({
  phone: z.string().min(10),
  otp: z.string().min(4),
  name: z.string().optional(),
});

async function issueAndStore(user) {
  const { token, refreshToken } = issueUserTokens(user);
  user.refreshTokenHash = hashToken(refreshToken);
  await user.save();
  return { token, refreshToken, user: meUser(user) };
}

router.post(
  '/send-otp',
  otpLimiter,
  validateBody(sendOtpSchema),
  asyncHandler(async (req, res) => {
    const phone = normalizePhone(req.body.phone);
    if (!isValidIndianPhone(phone)) throw new AppError(400, 'Invalid phone number');
    const code = env.mockOtp ? '123456' : String(Math.floor(100000 + Math.random() * 900000));
    const codeHash = await bcrypt.hash(code, 8);
    await Otp.deleteMany({ phone });
    await Otp.create({
      phone,
      codeHash,
      expiresAt: new Date(Date.now() + 10 * 60 * 1000),
    });
    if (env.mockOtp) {
      console.log(`[mock SMS] OTP for ${phone}: ${code}`);
    } else {
      console.log(`[SMS] OTP queued for ${phone}`);
    }
    const payload = { sent: true };
    if (!env.isProd && env.mockOtp) payload.devOtp = code;
    res.json(payload);
  })
);

router.post(
  '/verify-otp',
  verifyLimiter,
  validateBody(verifyOtpSchema),
  asyncHandler(async (req, res) => {
    const phone = normalizePhone(req.body.phone);
    const { otp, name } = req.body;
    if (!isValidIndianPhone(phone)) throw new AppError(400, 'Invalid phone number');

    const record = await Otp.findOne({ phone }).sort({ createdAt: -1 });
    const mockOk = env.mockOtp && otp === '123456';
    if (!mockOk) {
      if (!record) throw new AppError(400, 'OTP expired or not found');
      if (record.expiresAt < new Date()) throw new AppError(400, 'OTP expired');
      if (record.attempts >= 5) throw new AppError(429, 'Too many attempts');
      const ok = await bcrypt.compare(otp, record.codeHash);
      record.attempts += 1;
      await record.save();
      if (!ok) throw new AppError(400, 'Invalid OTP');
    }
    if (record) await Otp.deleteMany({ phone });

    let user = await User.findOne({ phone });
    if (!user) {
      user = await User.create({ phone, name: name || '', status: 'active' });
    } else if (name && !user.name) {
      user.name = name;
    }
    const result = await issueAndStore(user);
    res.json(result);
  })
);

router.post(
  '/firebase',
  validateBody(z.object({ idToken: z.string().min(10) })),
  asyncHandler(async (req, res) => {
    if (!env.firebaseEnabled) throw new AppError(501, 'Firebase auth is disabled', 'FIREBASE_DISABLED');
    const decoded = await verifyFirebaseIdToken(req.body.idToken);
    const rawPhone = decoded.phone_number || '';
    const phone = normalizePhone(rawPhone);
    if (!phone) throw new AppError(400, 'Firebase token has no phone number');
    let user = await User.findOne({ $or: [{ firebaseUid: decoded.uid }, { phone }] });
    if (!user) {
      user = await User.create({
        phone,
        firebaseUid: decoded.uid,
        name: decoded.name || '',
        status: 'active',
      });
    } else {
      user.firebaseUid = decoded.uid;
      if (!user.phone) user.phone = phone;
    }
    const result = await issueAndStore(user);
    res.json(result);
  })
);

router.post(
  '/refresh',
  validateBody(z.object({ refreshToken: z.string().min(10) })),
  asyncHandler(async (req, res) => {
    const payload = verifyRefreshToken(req.body.refreshToken);
    if (payload.typ !== 'refresh' || payload.kind === 'admin') {
      throw new AppError(401, 'Invalid refresh token');
    }
    const user = await User.findById(payload.sub);
    if (!user) throw new AppError(401, 'Invalid refresh token');
    if (user.refreshTokenHash !== hashToken(req.body.refreshToken)) {
      throw new AppError(401, 'Refresh token revoked');
    }
    const result = await issueAndStore(user);
    res.json(result);
  })
);

router.get(
  '/me',
  requireAuth,
  asyncHandler(async (req, res) => {
    if (req.user.kind === 'admin') {
      return res.json({ user: { id: req.user.id, role: 'admin', email: req.user.email } });
    }
    const user = req.authUser || (await User.findById(req.user.id));
    const worker = await WorkerProfile.findOne({ userId: user._id });
    const business = await BusinessProfile.findOne({ userId: user._id });
    res.json({
      user: meUser(user),
      workerProfile: worker,
      businessProfile: business,
    });
  })
);

module.exports = router;
