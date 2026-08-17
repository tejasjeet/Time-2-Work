const express = require('express');
const { z } = require('zod');
const { Job, JobApplication } = require('../models');
const { requireAuth } = require('../middleware/auth');
const { validateBody } = require('../middleware/validate');
const { AppError, asyncHandler } = require('../utils/errors');
const { applicationDto, chatDto } = require('../utils/serializers');
const { parsePagination, paginated } = require('../utils/pagination');
const { notifyUser } = require('../utils/notify');
const { ensureChat } = require('../services/jobs');

const router = express.Router();

router.get(
  '/mine',
  requireAuth,
  asyncHandler(async (req, res) => {
    const { page, limit, skip } = parsePagination(req.query);
    const filter = { workerId: req.user.id };
    const [items, total] = await Promise.all([
      JobApplication.find(filter)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .populate('jobId')
        .populate('workerId', 'name photoUrl role avgRating ratingCount verified status'),
      JobApplication.countDocuments(filter),
    ]);
    res.json(
      paginated(
        items.map((a) =>
          applicationDto({
            ...a.toObject(),
            job: a.jobId,
            worker: a.workerId,
          })
        ),
        { page, limit, total }
      )
    );
  })
);

router.patch(
  '/:id',
  requireAuth,
  validateBody(z.object({ status: z.enum(['shortlisted', 'accepted', 'rejected', 'cancelled']) })),
  asyncHandler(async (req, res) => {
    const app = await JobApplication.findById(req.params.id);
    if (!app) throw new AppError(404, 'Application not found');
    const job = await Job.findById(app.jobId);
    if (!job) throw new AppError(404, 'Job not found');

    const { status } = req.body;
    const isOwner = String(job.posterId) === req.user.id;
    const isWorker = String(app.workerId) === req.user.id;
    const isAdmin = req.user.role === 'admin';

    if (status === 'cancelled') {
      if (!isWorker && !isOwner && !isAdmin) throw new AppError(403, 'Not allowed');
    } else if (!isOwner && !isAdmin) {
      throw new AppError(403, 'Only the job owner can update this application');
    }

    if (status === 'accepted') {
      const acceptedCount = await JobApplication.countDocuments({
        jobId: job._id,
        status: 'accepted',
        _id: { $ne: app._id },
      });
      if (acceptedCount >= job.workersRequired) {
        throw new AppError(400, `Already accepted ${job.workersRequired} worker(s)`, 'CAPACITY');
      }
    }

    app.status = status;
    await app.save();

    let chat = null;
    if (status === 'accepted') {
      chat = await ensureChat(job, app);
      const stillNeeded = job.workersRequired - (await JobApplication.countDocuments({ jobId: job._id, status: 'accepted' }));
      if (stillNeeded <= 0 && (job.status === 'open' || job.status === 'draft')) {
        job.status = 'accepted';
        await job.save();
      }
    }

    await notifyUser(app.workerId, {
      title: `Application ${status}`,
      body: `Your application for "${job.title}" is ${status}.`,
      type: 'application',
      data: { jobId: String(job._id), applicationId: String(app._id), status },
    });

    const populated = await JobApplication.findById(app._id)
      .populate('workerId', 'name photoUrl role avgRating ratingCount verified status')
      .populate('jobId');
    res.json({
      application: applicationDto({
        ...populated.toObject(),
        worker: populated.workerId,
        job: populated.jobId,
      }),
      chat: chat ? chatDto(chat) : undefined,
    });
  })
);

module.exports = router;
