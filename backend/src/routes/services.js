const express = require('express');
const { z } = require('zod');
const { Service } = require('../models');
const { requireAuth, optionalAuth } = require('../middleware/auth');
const { validateBody } = require('../middleware/validate');
const { asyncHandler } = require('../utils/errors');
const { fromLatLng, toLatLng } = require('../utils/geo');
const { parsePagination, paginated } = require('../utils/pagination');

const router = express.Router();

function dto(s) {
  return {
    id: String(s._id),
    providerId: String(s.providerId),
    title: s.title,
    category: s.category,
    description: s.description,
    price: s.price,
    address: s.address,
    location: toLatLng(s.location),
    createdAt: s.createdAt,
  };
}

router.get(
  '/',
  optionalAuth,
  asyncHandler(async (req, res) => {
    const { page, limit, skip } = parsePagination(req.query);
    const filter = { active: true };
    if (req.query.category) filter.category = req.query.category;
    const [items, total] = await Promise.all([
      Service.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit),
      Service.countDocuments(filter),
    ]);
    res.json(paginated(items.map(dto), { page, limit, total }));
  })
);

router.post(
  '/',
  requireAuth,
  validateBody(
    z.object({
      title: z.string().min(2),
      category: z.string().optional(),
      description: z.string().optional(),
      price: z.number().optional(),
      lat: z.number().optional(),
      lng: z.number().optional(),
      address: z.string().optional(),
    })
  ),
  asyncHandler(async (req, res) => {
    const doc = await Service.create({
      providerId: req.user.id,
      title: req.body.title,
      category: req.body.category || '',
      description: req.body.description || '',
      price: req.body.price || 0,
      location: fromLatLng(req.body.lat, req.body.lng),
      address: req.body.address || '',
    });
    res.status(201).json({ service: dto(doc) });
  })
);

module.exports = router;
