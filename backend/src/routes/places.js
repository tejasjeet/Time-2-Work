const express = require('express');
const { optionalAuth } = require('../middleware/auth');
const { asyncHandler } = require('../utils/errors');
const { searchPlaces, resolvePlace, reverseGeocode } = require('../services/places');

const router = express.Router();

router.get(
  '/autocomplete',
  optionalAuth,
  asyncHandler(async (req, res) => {
    const q = String(req.query.q || '').trim();
    const lat = req.query.lat != null ? Number(req.query.lat) : undefined;
    const lng = req.query.lng != null ? Number(req.query.lng) : undefined;
    const results = await searchPlaces(q, { lat, lng });
    res.json({ results });
  })
);

router.get(
  '/details',
  optionalAuth,
  asyncHandler(async (req, res) => {
    const placeId = String(req.query.placeId || '').trim();
    const result = await resolvePlace(placeId);
    res.json({ result });
  })
);

router.get(
  '/reverse',
  optionalAuth,
  asyncHandler(async (req, res) => {
    const lat = Number(req.query.lat);
    const lng = Number(req.query.lng);
    const result = await reverseGeocode(lat, lng);
    res.json({ result });
  })
);

module.exports = router;
