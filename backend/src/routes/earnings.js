const express = require('express');
const { Transaction, JobApplication, Job } = require('../models');
const { requireAuth } = require('../middleware/auth');
const { asyncHandler } = require('../utils/errors');
const { transactionDto } = require('../utils/serializers');
const { parsePagination, paginated } = require('../utils/pagination');

const router = express.Router();

function startOfDay(d = new Date()) {
  const x = new Date(d);
  x.setHours(0, 0, 0, 0);
  return x;
}

router.get(
  '/',
  requireAuth,
  asyncHandler(async (req, res) => {
    const userId = req.user.id;
    const today = startOfDay();
    const week = startOfDay();
    week.setDate(week.getDate() - 6);
    const month = startOfDay();
    month.setDate(1);

    const payouts = await Transaction.find({ toUserId: userId, type: 'job_payout' });
    const sumNet = (list) => list.reduce((s, t) => s + (t.net || 0), 0);
    const completed = payouts.filter((t) => t.paymentStatus === 'completed');
    const pending = payouts.filter((t) => t.paymentStatus === 'pending');

    const apps = await JobApplication.find({ workerId: userId, status: 'accepted' }).select('jobId');
    const completedJobs = await Job.countDocuments({
      _id: { $in: apps.map((a) => a.jobId) },
      status: 'completed',
    });

    res.json({
      today: sumNet(completed.filter((t) => t.createdAt >= today)),
      week: sumNet(completed.filter((t) => t.createdAt >= week)),
      month: sumNet(completed.filter((t) => t.createdAt >= month)),
      total: sumNet(completed),
      pending: sumNet(pending),
      completedJobs,
    });
  })
);

const txRouter = express.Router();
txRouter.get(
  '/',
  requireAuth,
  asyncHandler(async (req, res) => {
    const { page, limit, skip } = parsePagination(req.query);
    const filter = { $or: [{ toUserId: req.user.id }, { fromUserId: req.user.id }] };
    const [items, total] = await Promise.all([
      Transaction.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit),
      Transaction.countDocuments(filter),
    ]);
    res.json(paginated(items.map(transactionDto), { page, limit, total }));
  })
);

module.exports = { earningsRouter: router, transactionsRouter: txRouter };
