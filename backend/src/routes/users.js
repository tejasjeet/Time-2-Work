const express = require('express');
const { z } = require('zod');
const { User, Report, Review } = require('../models');
const { requireAuth } = require('../middleware/auth');
const { validateBody } = require('../middleware/validate');
const { AppError, asyncHandler } = require('../utils/errors');
const { fromLatLng } = require('../utils/geo');
const { meUser, publicUser, reviewDto } = require('../utils/serializers');
const { parsePagination, paginated } = require('../utils/pagination');
const router = express.Router();

router.patch(
  '/me',
  requireAuth,
  validateBody(
    z.object({
      name: z.string().min(1).optional(),
      photoUrl: z.string().optional(),
      role: z.enum(['worker', 'business']).optional(),
      location: z
        .object({
          lat: z.coerce.number(),
          lng: z.coerce.number(),
          address: z.string().optional(),
        })
        .optional(),
      about: z.string().optional(),
      address: z.string().optional(),
    })
  ),
  asyncHandler(async (req, res) => {
    const user = req.authUser || (await User.findById(req.user.id));
    if (!user || req.user.kind === 'admin') throw new AppError(400, 'User profile not available');
    const { name, photoUrl, role, location, about, address } = req.body;
    if (name !== undefined) user.name = name;
    if (photoUrl !== undefined) user.photoUrl = photoUrl;
    if (role !== undefined) user.role = role;
    if (about !== undefined) user.about = about;
    if (address !== undefined) user.address = address;
    if (location) {
      user.location = fromLatLng(location.lat, location.lng);
      if (location.address) user.address = location.address;
    }
    await user.save();
    res.json({ user: meUser(user) });
  })
);

router.post(
  '/me/location',
  requireAuth,
  validateBody(
    z.object({
      lat: z.coerce.number(),
      lng: z.coerce.number(),
      address: z.string().optional(),
    })
  ),
  asyncHandler(async (req, res) => {
    const user = req.authUser || (await User.findById(req.user.id));
    if (!user || req.user.kind === 'admin') throw new AppError(400, 'User profile not available');
    user.location = fromLatLng(req.body.lat, req.body.lng);
    if (req.body.address) user.address = req.body.address;
    await user.save();
    res.json({ user: meUser(user) });
  })
);

router.post(
  '/me/role',
  requireAuth,
  validateBody(z.object({ role: z.enum(['worker', 'business']) })),
  asyncHandler(async (req, res) => {
    const user = req.authUser || (await User.findById(req.user.id));
    if (!user || req.user.kind === 'admin') throw new AppError(400, 'User profile not available');
    user.role = req.body.role;
    await user.save();
    res.json({ user: meUser(user) });
  })
);

router.post(
  '/:id/block',
  requireAuth,
  asyncHandler(async (req, res) => {
    if (req.params.id === req.user.id) throw new AppError(400, 'Cannot block yourself');
    const target = await User.findById(req.params.id);
    if (!target) throw new AppError(404, 'User not found');
    const user = req.authUser || (await User.findById(req.user.id));
    const already = (user.blockedUsers || []).some((b) => String(b) === req.params.id);
    if (!already) user.blockedUsers.push(target._id);
    await user.save();
    res.json({ blocked: true, userId: req.params.id });
  })
);

router.post(
  '/:id/report',
  requireAuth,
  validateBody(
    z.object({
      reason: z.string().min(2),
      details: z.string().optional(),
    })
  ),
  asyncHandler(async (req, res) => {
    const target = await User.findById(req.params.id);
    if (!target) throw new AppError(404, 'User not found');
    const report = await Report.create({
      reporterId: req.user.id,
      targetType: 'user',
      targetId: target._id,
      reason: req.body.reason,
      details: req.body.details || '',
    });
    res.status(201).json({
      id: String(report._id),
      status: report.status,
    });
  })
);

router.get(
  '/:id/reviews',
  asyncHandler(async (req, res) => {
    const { page, limit, skip } = parsePagination(req.query);
    const filter = { toUserId: req.params.id };
    const [items, total] = await Promise.all([
      Review.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit).populate('fromUserId', 'name photoUrl role avgRating ratingCount verified status'),
      Review.countDocuments(filter),
    ]);
    res.json(
      paginated(
        items.map((r) => reviewDto({ ...r.toObject(), fromUser: r.fromUserId })),
        { page, limit, total }
      )
    );
  })
);

module.exports = router;
