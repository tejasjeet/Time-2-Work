const express = require('express');
const { Job, User, WorkerProfile, BusinessProfile, Service, MarketplaceListing } = require('../models');
const { optionalAuth } = require('../middleware/auth');
const { asyncHandler } = require('../utils/errors');
const { publicUser, jobDto } = require('../utils/serializers');
const { parsePagination, paginated } = require('../utils/pagination');
const { allowedRadiusKm } = require('../utils/geo');
const { getSettings } = require('../utils/settings');

const router = express.Router();

router.get(
  '/',
  optionalAuth,
  asyncHandler(async (req, res) => {
    const q = String(req.query.q || '').trim();
    const type = req.query.type || 'jobs';
    const { page, limit, skip } = parsePagination(req.query);
    const settings = await getSettings();
    const radiusKm = allowedRadiusKm(req.query.radiusKm, settings);
    const { lat, lng } = req.query;
    const rx = q ? new RegExp(q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i') : null;

    const geoFilter = (field = 'location') => {
      if (lat == null || lng == null) return {};
      return {
        [field]: {
          $near: {
            $geometry: { type: 'Point', coordinates: [Number(lng), Number(lat)] },
            $maxDistance: radiusKm * 1000,
          },
        },
      };
    };

    if (type === 'jobs') {
      const filter = { status: 'open', ...geoFilter() };
      if (rx) filter.$or = [{ title: rx }, { description: rx }, { category: rx }];
      const [items, total] = await Promise.all([
        Job.find(filter).skip(skip).limit(limit).populate('posterId', 'name photoUrl role avgRating ratingCount verified status'),
        Job.countDocuments(rx ? { status: 'open', $or: filter.$or } : { status: 'open' }),
      ]);
      return res.json(
        paginated(
          items.map((j) => jobDto({ ...j.toObject(), poster: j.posterId })),
          { page, limit, total }
        )
      );
    }

    if (type === 'workers') {
      const wpFilter = {};
      if (rx) wpFilter.$or = [{ skills: rx }, { bio: rx }];
      const profiles = await WorkerProfile.find(wpFilter).skip(skip).limit(limit);
      const users = await User.find({
        _id: { $in: profiles.map((p) => p.userId) },
        status: 'active',
        ...(rx ? { $or: [{ name: rx }, { about: rx }] } : {}),
        ...geoFilter(),
      });
      const map = new Map(profiles.map((p) => [String(p.userId), p]));
      const data = users.map((u) => ({
        user: publicUser(u),
        profile: map.get(String(u._id)) || null,
      }));
      return res.json(paginated(data, { page, limit, total: data.length }));
    }

    if (type === 'businesses') {
      const filter = rx ? { $or: [{ businessName: rx }, { description: rx }, { category: rx }] } : {};
      const profiles = await BusinessProfile.find(filter).skip(skip).limit(limit);
      const users = await User.find({ _id: { $in: profiles.map((p) => p.userId) }, status: 'active' });
      const umap = new Map(users.map((u) => [String(u._id), u]));
      const data = profiles
        .filter((p) => umap.has(String(p.userId)))
        .map((p) => ({ user: publicUser(umap.get(String(p.userId))), profile: p }));
      return res.json(paginated(data, { page, limit, total: data.length }));
    }

    if (type === 'services') {
      const filter = { active: true, ...geoFilter() };
      if (rx) filter.$or = [{ title: rx }, { description: rx }, { category: rx }];
      const [items, total] = await Promise.all([
        Service.find(filter).skip(skip).limit(limit),
        Service.countDocuments(filter),
      ]);
      return res.json(paginated(items, { page, limit, total }));
    }

    if (type === 'products') {
      const filter = { status: 'active', ...geoFilter() };
      if (rx) filter.$or = [{ title: rx }, { description: rx }, { category: rx }];
      const [items, total] = await Promise.all([
        MarketplaceListing.find(filter).skip(skip).limit(limit),
        MarketplaceListing.countDocuments(filter),
      ]);
      return res.json(paginated(items, { page, limit, total }));
    }

    res.json(paginated([], { page, limit, total: 0 }));
  })
);

module.exports = router;
