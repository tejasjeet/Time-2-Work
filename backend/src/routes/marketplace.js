const express = require('express');
const { z } = require('zod');
const { MarketplaceListing } = require('../models');
const { requireAuth, optionalAuth } = require('../middleware/auth');
const { validateBody } = require('../middleware/validate');
const { asyncHandler } = require('../utils/errors');
const { fromLatLng, toLatLng } = require('../utils/geo');
const { parsePagination, paginated } = require('../utils/pagination');

const router = express.Router();

function dto(s) {
  return {
    id: String(s._id),
    sellerId: String(s.sellerId),
    title: s.title,
    description: s.description,
    price: s.price,
    images: s.images,
    category: s.category,
    address: s.address,
    location: toLatLng(s.location),
    status: s.status,
    createdAt: s.createdAt,
  };
}

router.get(
  '/',
  optionalAuth,
  asyncHandler(async (req, res) => {
    const { page, limit, skip } = parsePagination(req.query);
    const filter = { status: 'active' };
    if (req.query.category) filter.category = req.query.category;
    const [items, total] = await Promise.all([
      MarketplaceListing.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit),
      MarketplaceListing.countDocuments(filter),
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
      description: z.string().optional(),
      price: z.number().optional(),
      images: z.array(z.string()).optional(),
      category: z.string().optional(),
      lat: z.number().optional(),
      lng: z.number().optional(),
      address: z.string().optional(),
    })
  ),
  asyncHandler(async (req, res) => {
    const doc = await MarketplaceListing.create({
      sellerId: req.user.id,
      title: req.body.title,
      description: req.body.description || '',
      price: req.body.price || 0,
      images: req.body.images || [],
      category: req.body.category || '',
      location: fromLatLng(req.body.lat, req.body.lng),
      address: req.body.address || '',
      status: 'active',
    });
    res.status(201).json({ listing: dto(doc) });
  })
);

module.exports = router;
