const express = require('express');
const { z } = require('zod');
const { Notification, User } = require('../models');
const { requireAuth } = require('../middleware/auth');
const { validateBody } = require('../middleware/validate');
const { AppError, asyncHandler } = require('../utils/errors');
const { notificationDto } = require('../utils/serializers');
const { parsePagination, paginated } = require('../utils/pagination');

const router = express.Router();

router.get(
  '/',
  requireAuth,
  asyncHandler(async (req, res) => {
    const { page, limit, skip } = parsePagination(req.query);
    const filter = { userId: req.user.id };
    const [items, total] = await Promise.all([
      Notification.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit),
      Notification.countDocuments(filter),
    ]);
    res.json(paginated(items.map(notificationDto), { page, limit, total }));
  })
);

router.patch(
  '/:id/read',
  requireAuth,
  asyncHandler(async (req, res) => {
    const doc = await Notification.findOneAndUpdate(
      { _id: req.params.id, userId: req.user.id },
      { $set: { read: true } },
      { new: true }
    );
    if (!doc) throw new AppError(404, 'Notification not found');
    res.json({ notification: notificationDto(doc) });
  })
);

router.delete(
  '/:id',
  requireAuth,
  asyncHandler(async (req, res) => {
    const doc = await Notification.findOneAndDelete({ _id: req.params.id, userId: req.user.id });
    if (!doc) throw new AppError(404, 'Notification not found');
    res.json({ deleted: true });
  })
);

router.post(
  '/register-fcm',
  requireAuth,
  validateBody(z.object({ token: z.string().min(8) })),
  asyncHandler(async (req, res) => {
    await User.findByIdAndUpdate(req.user.id, { $addToSet: { fcmTokens: req.body.token } });
    res.json({ registered: true });
  })
);

module.exports = router;
