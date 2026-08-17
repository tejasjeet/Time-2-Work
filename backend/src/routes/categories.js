const express = require('express');
const { Category } = require('../models');
const { asyncHandler } = require('../utils/errors');

const router = express.Router();

router.get(
  '/',
  asyncHandler(async (req, res) => {
    const items = await Category.find({ active: true }).sort({ sortOrder: 1, name: 1 });
    res.json({
      data: items.map((c) => ({
        id: String(c._id),
        slug: c.slug,
        name: c.name,
        nameHi: c.nameHi,
        icon: c.icon,
      })),
    });
  })
);

module.exports = router;
