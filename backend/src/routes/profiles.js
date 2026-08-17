const express = require('express');
const { z } = require('zod');
const { User, WorkerProfile, BusinessProfile } = require('../models');
const { requireAuth } = require('../middleware/auth');
const { validateBody } = require('../middleware/validate');
const { AppError, asyncHandler } = require('../utils/errors');
const { publicUser } = require('../utils/serializers');
const { toLatLng } = require('../utils/geo');

const router = express.Router();

const workerSchema = z.object({
  skills: z.array(z.string()).optional(),
  experienceYears: z.number().optional(),
  availableNow: z.boolean().optional(),
  hourlyRate: z.number().optional(),
  bio: z.string().optional(),
  languages: z.array(z.string()).optional(),
});

const businessSchema = z.object({
  businessName: z.string().optional(),
  category: z.string().optional(),
  description: z.string().optional(),
  address: z.string().optional(),
  gstin: z.string().optional(),
});

router.get(
  '/worker',
  requireAuth,
  asyncHandler(async (req, res) => {
    const profile = await WorkerProfile.findOne({ userId: req.user.id });
    res.json({ profile: profile || null });
  })
);

router.put(
  '/worker',
  requireAuth,
  validateBody(workerSchema),
  asyncHandler(async (req, res) => {
    const profile = await WorkerProfile.findOneAndUpdate(
      { userId: req.user.id },
      { $set: { ...req.body, userId: req.user.id } },
      { new: true, upsert: true }
    );
    const user = await User.findById(req.user.id);
    if (user && !user.role) {
      user.role = 'worker';
      await user.save();
    }
    res.json({ profile });
  })
);

router.patch(
  '/worker/availability',
  requireAuth,
  validateBody(z.object({ availableNow: z.boolean() })),
  asyncHandler(async (req, res) => {
    const profile = await WorkerProfile.findOneAndUpdate(
      { userId: req.user.id },
      { $set: { availableNow: req.body.availableNow, userId: req.user.id } },
      { new: true, upsert: true }
    );
    res.json({ profile });
  })
);

router.get(
  '/business',
  requireAuth,
  asyncHandler(async (req, res) => {
    const profile = await BusinessProfile.findOne({ userId: req.user.id });
    res.json({ profile: profile || null });
  })
);

router.put(
  '/business',
  requireAuth,
  validateBody(businessSchema),
  asyncHandler(async (req, res) => {
    const profile = await BusinessProfile.findOneAndUpdate(
      { userId: req.user.id },
      { $set: { ...req.body, userId: req.user.id } },
      { new: true, upsert: true }
    );
    const user = await User.findById(req.user.id);
    if (user && !user.role) {
      user.role = 'business';
      await user.save();
    }
    res.json({ profile });
  })
);

router.get(
  '/:userId',
  asyncHandler(async (req, res) => {
    const user = await User.findById(req.params.userId);
    if (!user) throw new AppError(404, 'User not found');
    const worker = await WorkerProfile.findOne({ userId: user._id });
    const business = await BusinessProfile.findOne({ userId: user._id });
    res.json({
      user: {
        ...publicUser(user),
        address: user.address || '',
        locationApprox: user.address || '',
        location: user.address ? null : toLatLng(user.location) ? { area: user.address } : null,
      },
      workerProfile: worker
        ? {
            skills: worker.skills,
            experienceYears: worker.experienceYears,
            availableNow: worker.availableNow,
            hourlyRate: worker.hourlyRate,
            bio: worker.bio,
            languages: worker.languages,
          }
        : null,
      businessProfile: business
        ? {
            businessName: business.businessName,
            category: business.category,
            description: business.description,
            address: business.address,
          }
        : null,
    });
  })
);

module.exports = router;
