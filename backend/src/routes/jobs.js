const express = require('express');
const { z } = require('zod');
const mongoose = require('mongoose');
const { Job, JobApplication, WorkerProfile, User, Category } = require('../models');
const { requireAuth, optionalAuth } = require('../middleware/auth');
const { validateBody } = require('../middleware/validate');
const { AppError, asyncHandler } = require('../utils/errors');
const { fromLatLng, allowedRadiusKm } = require('../utils/geo');
const { getSettings } = require('../utils/settings');
const { jobDto, applicationDto, paymentDto } = require('../utils/serializers');
const { parsePagination, paginated } = require('../utils/pagination');
const { notifyUser } = require('../utils/notify');
const { createOrder, markPaid } = require('../services/payments');
const {
  assertNoDuplicateJob,
  ensureChat,
  updateJobStatus,
  blockedSetFor,
} = require('../services/jobs');

const router = express.Router();

const jobBodySchema = z.object({
  title: z.string().min(3),
  description: z.string().optional(),
  category: z.string().min(1),
  pay: z.coerce.number().positive(),
  payType: z.enum(['fixed', 'hourly', 'daily']).optional(),
  workersRequired: z.coerce.number().int().min(1).optional(),
  date: z.string().or(z.coerce.date()).optional(),
  timeSlot: z.string().optional(),
  lat: z.coerce.number().optional(),
  lng: z.coerce.number().optional(),
  location: z.object({ lat: z.coerce.number(), lng: z.coerce.number() }).optional(),
  address: z.string().optional(),
});

function jobLocation(body) {
  if (body.location) return fromLatLng(body.location.lat, body.location.lng);
  if (body.lat != null && body.lng != null) return fromLatLng(body.lat, body.lng);
  return undefined;
}

router.get(
  '/',
  optionalAuth,
  asyncHandler(async (req, res) => {
    const settings = await getSettings();
    const { lat, lng, category, minPay, date, radiusKm: radiusQuery } = req.query;
    const { page, limit, skip } = parsePagination(req.query);
    const hasRadiusFilter = radiusQuery != null && radiusQuery !== '';
    const radiusKm = hasRadiusFilter ? allowedRadiusKm(radiusQuery, settings) : null;
    const blocked = await blockedSetFor(req.user?.id);

    const match = { status: 'open' };
    if (category) {
      const slug = String(category).trim();
      if (mongoose.isValidObjectId(slug)) {
        const cat = await Category.findById(slug).select('slug');
        match.category = cat?.slug || slug;
      } else {
        match.category = slug;
      }
    }
    if (minPay) match.pay = { $gte: Number(minPay) };
    if (date) {
      const start = new Date(date);
      start.setHours(0, 0, 0, 0);
      const end = new Date(start);
      end.setDate(end.getDate() + 1);
      match.date = { $gte: start, $lt: end };
    }
    if (blocked.size) match.posterId = { $nin: [...blocked].map((id) => new mongoose.Types.ObjectId(id)) };

    let workerSkills = [];
    if (req.user?.id) {
      const wp = await WorkerProfile.findOne({ userId: req.user.id });
      workerSkills = wp?.skills || [];
    }

    if (lat != null && lng != null) {
      const geoNear = {
        near: { type: 'Point', coordinates: [Number(lng), Number(lat)] },
        distanceField: 'distance',
        spherical: true,
        query: match,
      };
      if (hasRadiusFilter && radiusKm != null) {
        geoNear.maxDistance = radiusKm * 1000;
      }
      const maxDistance = geoNear.maxDistance ?? Number.MAX_SAFE_INTEGER;
      const now = Date.now();
      const pipeline = [
        {
          $geoNear: geoNear,
        },
        {
          $addFields: {
            score: {
              $add: [
                { $multiply: [{ $subtract: [1, { $divide: ['$distance', maxDistance] }] }, 40] },
                {
                  $cond: [
                    {
                      $or: [
                        { $in: ['$category', workerSkills] },
                        { $eq: [category || '', '$category'] },
                      ],
                    },
                    25,
                    0,
                  ],
                },
                {
                  $multiply: [
                    {
                      $max: [
                        0,
                        {
                          $subtract: [
                            1,
                            { $divide: [{ $subtract: [now, { $toLong: '$createdAt' }] }, 7 * 24 * 3600 * 1000] },
                          ],
                        },
                      ],
                    },
                    20,
                  ],
                },
                { $multiply: [{ $min: [{ $divide: ['$pay', 2000] }, 1] }, 10] },
                { $multiply: [{ $min: [{ $divide: [{ $ifNull: ['$posterRating', 0] }, 5] }, 1] }, 5] },
              ],
            },
          },
        },
        { $sort: { score: -1, createdAt: -1 } },
        {
          $facet: {
            data: [{ $skip: skip }, { $limit: limit }],
            total: [{ $count: 'count' }],
          },
        },
      ];
      const [result] = await Job.aggregate(pipeline);
      const docs = result.data || [];
      const total = result.total[0]?.count || 0;
      const posterIds = docs.map((d) => d.posterId);
      const posters = await User.find({ _id: { $in: posterIds } }).select(
        'name photoUrl role avgRating ratingCount verified status'
      );
      const posterMap = new Map(posters.map((p) => [String(p._id), p]));
      const data = docs.map((d) =>
        jobDto({ ...d, poster: posterMap.get(String(d.posterId)) }, { score: d.score })
      );
      return res.json(paginated(data, { page, limit, total }));
    }

    const [items, total] = await Promise.all([
      Job.find(match).sort({ createdAt: -1 }).skip(skip).limit(limit).populate('posterId', 'name photoUrl role avgRating ratingCount verified status'),
      Job.countDocuments(match),
    ]);
    res.json(
      paginated(
        items.map((j) => jobDto({ ...j.toObject(), poster: j.posterId })),
        { page, limit, total }
      )
    );
  })
);

router.get(
  '/mine',
  requireAuth,
  asyncHandler(async (req, res) => {
    const { page, limit, skip } = parsePagination(req.query);
    const filter = { posterId: req.user.id };
    const [items, total] = await Promise.all([
      Job.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit),
      Job.countDocuments(filter),
    ]);
    res.json(paginated(items.map((j) => jobDto(j)), { page, limit, total }));
  })
);

router.get(
  '/:id/applications',
  requireAuth,
  asyncHandler(async (req, res) => {
    const job = await Job.findById(req.params.id);
    if (!job) throw new AppError(404, 'Job not found');
    if (String(job.posterId) !== req.user.id && req.user.role !== 'admin') {
      throw new AppError(403, 'Not the job owner');
    }
    const { page, limit, skip } = parsePagination(req.query);
    const filter = { jobId: job._id };
    const [items, total] = await Promise.all([
      JobApplication.find(filter)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .populate('workerId', 'name photoUrl role avgRating ratingCount verified status'),
      JobApplication.countDocuments(filter),
    ]);
    res.json(
      paginated(
        items.map((a) => applicationDto({ ...a.toObject(), worker: a.workerId, jobId: job._id })),
        { page, limit, total }
      )
    );
  })
);

router.get(
  '/:id',
  optionalAuth,
  asyncHandler(async (req, res) => {
    const job = await Job.findById(req.params.id).populate(
      'posterId',
      'name photoUrl role avgRating ratingCount verified status'
    );
    if (!job) throw new AppError(404, 'Job not found');
    const settings = await getSettings();
    res.json({
      job: jobDto({ ...job.toObject(), poster: job.posterId, postingFee: job.postingFee || settings.jobPostingFee }),
    });
  })
);

router.post(
  '/',
  requireAuth,
  validateBody(jobBodySchema),
  asyncHandler(async (req, res) => {
    const settings = await getSettings();
    await assertNoDuplicateJob(req.user.id, req.body.title, req.body.date);
    const user = req.authUser || (await User.findById(req.user.id));
    const loc = jobLocation(req.body) || user?.location;
    const job = await Job.create({
      posterId: req.user.id,
      title: req.body.title,
      description: req.body.description || '',
      category: req.body.category,
      pay: req.body.pay,
      payType: req.body.payType || 'fixed',
      workersRequired: req.body.workersRequired || 1,
      date: req.body.date ? new Date(req.body.date) : new Date(),
      timeSlot: req.body.timeSlot || '',
      location: loc,
      address: req.body.address || user?.address || '',
      status: 'draft',
      feePaid: false,
      postingFee: settings.jobPostingFee,
      posterRating: user?.avgRating || 0,
    });
    res.status(201).json({ job: jobDto(job), postingFee: settings.jobPostingFee });
  })
);

router.post(
  '/:id/pay-fee',
  requireAuth,
  validateBody(z.object({ method: z.enum(['mock', 'razorpay']) })),
  asyncHandler(async (req, res) => {
    const job = await Job.findById(req.params.id);
    if (!job) throw new AppError(404, 'Job not found');
    if (String(job.posterId) !== req.user.id) throw new AppError(403, 'Not the job owner');
    const payment = await createOrder({
      userId: req.user.id,
      type: 'job_fee',
      jobId: job._id,
      method: req.body.method,
    });
    if (req.body.method === 'mock') {
      await markPaid(payment);
      await job.populate('posterId');
    }
    const fresh = await Job.findById(job._id);
    res.json({ payment: paymentDto(payment), job: jobDto(fresh), feePaid: fresh.feePaid });
  })
);

router.post(
  '/:id/publish',
  requireAuth,
  asyncHandler(async (req, res) => {
    const job = await Job.findById(req.params.id);
    if (!job) throw new AppError(404, 'Job not found');
    if (String(job.posterId) !== req.user.id && req.user.role !== 'admin') {
      throw new AppError(403, 'Not the job owner');
    }
    if (!job.feePaid) throw new AppError(402, 'Posting fee required before publish', 'FEE_REQUIRED');
    if (!job.location?.coordinates) throw new AppError(400, 'Job location is required to publish');
    await assertNoDuplicateJob(job.posterId, job.title, job.createdAt, job._id);
    job.status = 'open';
    await job.save();
    res.json({ job: jobDto(job) });
  })
);

router.patch(
  '/:id/status',
  requireAuth,
  validateBody(z.object({ status: z.enum(['accepted', 'started', 'in_progress', 'completed', 'cancelled']) })),
  asyncHandler(async (req, res) => {
    const job = await Job.findById(req.params.id);
    if (!job) throw new AppError(404, 'Job not found');
    const updated = await updateJobStatus(job, req.body.status, req.user.id, req.user.role === 'admin');
    res.json({ job: jobDto(updated) });
  })
);

router.delete(
  '/:id',
  requireAuth,
  asyncHandler(async (req, res) => {
    const job = await Job.findById(req.params.id);
    if (!job) throw new AppError(404, 'Job not found');
    const owner = String(job.posterId) === req.user.id;
    if (!owner && req.user.role !== 'admin') throw new AppError(403, 'Not allowed');
    const accepted = await JobApplication.countDocuments({ jobId: job._id, status: 'accepted' });
    if (accepted > 0 && job.status !== 'cancelled' && job.status !== 'draft' && req.user.role !== 'admin') {
      throw new AppError(400, 'Cancel the job before deleting after workers were accepted');
    }
    await job.deleteOne();
    res.json({ deleted: true, id: req.params.id });
  })
);

router.post(
  '/:id/apply',
  requireAuth,
  validateBody(z.object({ message: z.string().optional() })),
  asyncHandler(async (req, res) => {
    const job = await Job.findById(req.params.id);
    if (!job) throw new AppError(404, 'Job not found');
    if (job.status !== 'open') throw new AppError(400, 'Job is not open for applications');
    if (String(job.posterId) === req.user.id) throw new AppError(400, 'Cannot apply to your own job');
    const blocked = await blockedSetFor(req.user.id);
    if (blocked.has(String(job.posterId))) throw new AppError(403, 'Cannot apply to this poster');
    try {
      const app = await JobApplication.create({
        jobId: job._id,
        workerId: req.user.id,
        status: 'applied',
        message: req.body?.message || '',
      });
      await notifyUser(job.posterId, {
        title: 'New application',
        body: `${req.authUser?.name || 'A worker'} tapped I Can Do It on "${job.title}".`,
        type: 'application',
        data: { jobId: String(job._id), applicationId: String(app._id) },
      });
      const populated = await app.populate('workerId', 'name photoUrl role avgRating ratingCount verified status');
      res.status(201).json({
        application: applicationDto({ ...populated.toObject(), worker: populated.workerId }),
      });
    } catch (err) {
      if (err.code === 11000) throw new AppError(409, 'Already applied');
      throw err;
    }
  })
);

router.post(
  '/:id/rate',
  requireAuth,
  validateBody(
    z.object({
      toUserId: z.string().min(1),
      stars: z.number().int().min(1).max(5),
      review: z.string().optional(),
    })
  ),
  asyncHandler(async (req, res) => {
    const { Rating, Review } = require('../models');
    const job = await Job.findById(req.params.id);
    if (!job) throw new AppError(404, 'Job not found');
    if (job.status !== 'completed') throw new AppError(400, 'Rate only after the job is completed');
    if (req.body.toUserId === req.user.id) throw new AppError(400, 'Cannot rate yourself');

    const isPoster = String(job.posterId) === req.user.id;
    const myApp = await JobApplication.findOne({ jobId: job._id, workerId: req.user.id, status: 'accepted' });
    const theirApp = await JobApplication.findOne({
      jobId: job._id,
      workerId: req.body.toUserId,
      status: 'accepted',
    });
    const ratingPoster = String(job.posterId) === req.body.toUserId;
    if (!isPoster && !myApp) throw new AppError(403, 'Not part of this job');
    if (isPoster && !theirApp) throw new AppError(400, 'Can only rate accepted workers');
    if (!isPoster && !ratingPoster) throw new AppError(400, 'Workers can rate the poster');

    const rating = await Rating.findOneAndUpdate(
      { jobId: job._id, fromUserId: req.user.id, toUserId: req.body.toUserId },
      { $set: { stars: req.body.stars } },
      { new: true, upsert: true }
    );
    const review = await Review.findOneAndUpdate(
      { jobId: job._id, fromUserId: req.user.id, toUserId: req.body.toUserId },
      {
        $set: {
          stars: req.body.stars,
          review: req.body.review || '',
          ratingId: rating._id,
        },
      },
      { new: true, upsert: true }
    );

    const agg = await Rating.aggregate([
      { $match: { toUserId: new mongoose.Types.ObjectId(req.body.toUserId) } },
      { $group: { _id: '$toUserId', avg: { $avg: '$stars' }, count: { $sum: 1 } } },
    ]);
    if (agg[0]) {
      await User.findByIdAndUpdate(req.body.toUserId, {
        avgRating: Math.round(agg[0].avg * 10) / 10,
        ratingCount: agg[0].count,
      });
    }
    await notifyUser(req.body.toUserId, {
      title: 'New rating',
      body: `You received ${req.body.stars}★`,
      type: 'rating',
      data: { jobId: String(job._id) },
    });
    res.status(201).json({
      rating: { id: String(rating._id), stars: rating.stars },
      review: { id: String(review._id), stars: review.stars, review: review.review },
    });
  })
);

module.exports = router;
