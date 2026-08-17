const express = require('express');
const bcrypt = require('bcryptjs');
const { z } = require('zod');
const {
  AdminUser,
  User,
  Job,
  Category,
  Payment,
  Transaction,
  Report,
  Settings,
} = require('../models');
const { requireAdmin } = require('../middleware/adminAuth');
const { validateBody } = require('../middleware/validate');
const { AppError, asyncHandler } = require('../utils/errors');
const { issueAdminTokens } = require('../utils/jwt');
const { publicAdmin, publicUser, jobDto, paymentDto, transactionDto } = require('../utils/serializers');
const { parsePagination, paginated } = require('../utils/pagination');
const { getSettings, clearSettingsCache, settingsDto } = require('../utils/settings');

const router = express.Router();

router.post(
  '/login',
  validateBody(z.object({ email: z.string().email(), password: z.string().min(6) })),
  asyncHandler(async (req, res) => {
    const admin = await AdminUser.findOne({ email: req.body.email.toLowerCase() });
    if (!admin) throw new AppError(401, 'Invalid credentials');
    const ok = await bcrypt.compare(req.body.password, admin.passwordHash);
    if (!ok) throw new AppError(401, 'Invalid credentials');
    const { token, refreshToken } = issueAdminTokens(admin);
    res.json({ token, refreshToken, admin: publicAdmin(admin) });
  })
);

router.get(
  '/analytics',
  requireAdmin,
  asyncHandler(async (req, res) => {
    const [users, activeUsers, jobsPosted, jobsCompleted, feeAgg, commissionAgg] = await Promise.all([
      User.countDocuments(),
      User.countDocuments({ status: 'active' }),
      Job.countDocuments({ status: { $ne: 'draft' } }),
      Job.countDocuments({ status: 'completed' }),
      Transaction.aggregate([
        { $match: { type: 'job_fee', paymentStatus: 'completed' } },
        { $group: { _id: null, total: { $sum: '$gross' } } },
      ]),
      Transaction.aggregate([
        { $match: { type: 'job_payout' } },
        { $group: { _id: null, total: { $sum: '$commission' } } },
      ]),
    ]);
    res.json({
      users,
      activeUsers,
      jobsPosted,
      jobsCompleted,
      revenue: feeAgg[0]?.total || 0,
      commission: commissionAgg[0]?.total || 0,
    });
  })
);

router.get(
  '/users',
  requireAdmin,
  asyncHandler(async (req, res) => {
    const { page, limit, skip } = parsePagination(req.query);
    const q = String(req.query.q || '').trim();
    const filter = {};
    if (q) {
      const rx = new RegExp(q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
      filter.$or = [{ name: rx }, { phone: rx }, { about: rx }];
    }
    const [items, total] = await Promise.all([
      User.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit),
      User.countDocuments(filter),
    ]);
    res.json(
      paginated(
        items.map((u) => ({ ...publicUser(u, { includeLocation: true }), phone: u.phone })),
        { page, limit, total }
      )
    );
  })
);

router.patch(
  '/users/:id',
  requireAdmin,
  validateBody(
    z.object({
      status: z.enum(['active', 'suspended', 'blocked']).optional(),
      verified: z.boolean().optional(),
    })
  ),
  asyncHandler(async (req, res) => {
    const user = await User.findById(req.params.id);
    if (!user) throw new AppError(404, 'User not found');
    if (req.body.status !== undefined) user.status = req.body.status;
    if (req.body.verified !== undefined) user.verified = req.body.verified;
    await user.save();
    res.json({ user: { ...publicUser(user), phone: user.phone } });
  })
);

router.get(
  '/jobs',
  requireAdmin,
  asyncHandler(async (req, res) => {
    const { page, limit, skip } = parsePagination(req.query);
    const filter = {};
    if (req.query.status) filter.status = req.query.status;
    const [items, total] = await Promise.all([
      Job.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit).populate('posterId', 'name photoUrl role avgRating ratingCount verified status'),
      Job.countDocuments(filter),
    ]);
    res.json(
      paginated(
        items.map((j) => jobDto({ ...j.toObject(), poster: j.posterId })),
        { page, limit, total }
      )
    );
  })
);

router.delete(
  '/jobs/:id',
  requireAdmin,
  asyncHandler(async (req, res) => {
    const job = await Job.findById(req.params.id);
    if (!job) throw new AppError(404, 'Job not found');
    await job.deleteOne();
    res.json({ deleted: true, id: req.params.id });
  })
);

router.get(
  '/categories',
  requireAdmin,
  asyncHandler(async (req, res) => {
    const items = await Category.find().sort({ sortOrder: 1, name: 1 });
    res.json({ data: items });
  })
);

router.post(
  '/categories',
  requireAdmin,
  validateBody(
    z.object({
      slug: z.string().min(2),
      name: z.string().min(2),
      nameHi: z.string().optional(),
      icon: z.string().optional(),
      active: z.boolean().optional(),
      sortOrder: z.number().optional(),
    })
  ),
  asyncHandler(async (req, res) => {
    const doc = await Category.create(req.body);
    res.status(201).json({ category: doc });
  })
);

router.patch(
  '/categories/:id',
  requireAdmin,
  validateBody(
    z.object({
      slug: z.string().optional(),
      name: z.string().optional(),
      nameHi: z.string().optional(),
      icon: z.string().optional(),
      active: z.boolean().optional(),
      sortOrder: z.number().optional(),
    })
  ),
  asyncHandler(async (req, res) => {
    const doc = await Category.findByIdAndUpdate(req.params.id, { $set: req.body }, { new: true });
    if (!doc) throw new AppError(404, 'Category not found');
    res.json({ category: doc });
  })
);

router.put(
  '/categories/:id',
  requireAdmin,
  validateBody(
    z.object({
      slug: z.string().optional(),
      name: z.string().optional(),
      nameHi: z.string().optional(),
      icon: z.string().optional(),
      active: z.boolean().optional(),
      sortOrder: z.number().optional(),
    })
  ),
  asyncHandler(async (req, res) => {
    const doc = await Category.findByIdAndUpdate(req.params.id, { $set: req.body }, { new: true });
    if (!doc) throw new AppError(404, 'Category not found');
    res.json({ category: doc });
  })
);

router.delete(
  '/categories/:id',
  requireAdmin,
  asyncHandler(async (req, res) => {
    const doc = await Category.findByIdAndDelete(req.params.id);
    if (!doc) throw new AppError(404, 'Category not found');
    res.json({ deleted: true, id: req.params.id });
  })
);

router.get(
  '/payments',
  requireAdmin,
  asyncHandler(async (req, res) => {
    const { page, limit, skip } = parsePagination(req.query);
    const [payments, pTotal, transactions, tTotal] = await Promise.all([
      Payment.find().sort({ createdAt: -1 }).skip(skip).limit(limit),
      Payment.countDocuments(),
      Transaction.find().sort({ createdAt: -1 }).skip(skip).limit(limit),
      Transaction.countDocuments(),
    ]);
    res.json({
      payments: paginated(payments.map(paymentDto), { page, limit, total: pTotal }),
      transactions: paginated(transactions.map(transactionDto), { page, limit, total: tTotal }),
    });
  })
);

router.get(
  '/reports',
  requireAdmin,
  asyncHandler(async (req, res) => {
    const { page, limit, skip } = parsePagination(req.query);
    const filter = {};
    if (req.query.status) filter.status = req.query.status;
    const [items, total] = await Promise.all([
      Report.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit).populate('reporterId', 'name photoUrl role status'),
      Report.countDocuments(filter),
    ]);
    res.json(
      paginated(
        items.map((r) => ({
          id: String(r._id),
          reporter: r.reporterId && r.reporterId.name !== undefined ? publicUser(r.reporterId) : { id: String(r.reporterId) },
          targetType: r.targetType,
          targetId: r.targetId ? String(r.targetId) : null,
          reason: r.reason,
          details: r.details,
          status: r.status,
          adminNote: r.adminNote,
          createdAt: r.createdAt,
        })),
        { page, limit, total }
      )
    );
  })
);

router.patch(
  '/reports/:id',
  requireAdmin,
  validateBody(
    z.object({
      status: z.enum(['open', 'reviewed', 'resolved', 'dismissed']).optional(),
      adminNote: z.string().optional(),
    })
  ),
  asyncHandler(async (req, res) => {
    const doc = await Report.findByIdAndUpdate(req.params.id, { $set: req.body }, { new: true });
    if (!doc) throw new AppError(404, 'Report not found');
    res.json({
      report: {
        id: String(doc._id),
        status: doc.status,
        adminNote: doc.adminNote,
      },
    });
  })
);

router.get(
  '/settings',
  requireAdmin,
  asyncHandler(async (req, res) => {
    const s = await getSettings();
    res.json({ settings: settingsDto(s) });
  })
);

router.put(
  '/settings',
  requireAdmin,
  validateBody(
    z.object({
      jobPostingFee: z.number().min(0).optional(),
      commissionPercent: z.number().min(0).max(100).optional(),
      referralReward: z.number().min(0).optional(),
      primaryRadiusKm: z.number().positive().optional(),
      secondaryRadiusKm: z.number().positive().optional(),
    })
  ),
  asyncHandler(async (req, res) => {
    const current = await getSettings();
    Object.assign(current, req.body);
    await current.save();
    clearSettingsCache();
    res.json({ settings: settingsDto(current) });
  })
);

module.exports = router;
