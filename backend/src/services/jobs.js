const { Job, JobApplication, Transaction, Chat, User } = require('../models');
const { AppError } = require('../utils/errors');
const { uniqueTxnId } = require('../utils/ids');
const { getSettings } = require('../utils/settings');
const { env } = require('../config/env');
const { notifyUser } = require('../utils/notify');

const STATUS_FLOW = ['accepted', 'started', 'in_progress', 'completed'];

async function assertNoDuplicateJob(posterId, title, date, excludeId) {
  const day = new Date(date || Date.now());
  const start = new Date(day);
  start.setHours(0, 0, 0, 0);
  const end = new Date(start);
  end.setDate(end.getDate() + 1);
  const filter = {
    posterId,
    title: new RegExp(`^${escapeRegex(title)}$`, 'i'),
    createdAt: { $gte: start, $lt: end },
    status: { $ne: 'cancelled' },
  };
  if (excludeId) filter._id = { $ne: excludeId };
  const existing = await Job.findOne(filter);
  if (existing) throw new AppError(409, 'A similar job was already posted today', 'DUPLICATE_JOB');
}

function escapeRegex(s) {
  return String(s).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

async function ensureChat(job, application) {
  let chat = await Chat.findOne({
    jobId: job._id,
    applicationId: application._id,
  });
  if (!chat) {
    chat = await Chat.create({
      jobId: job._id,
      applicationId: application._id,
      participants: [job.posterId, application.workerId],
    });
  }
  return chat;
}

async function settleCompletedJob(job) {
  const existingCount = await Transaction.countDocuments({ jobId: job._id, type: 'job_payout' });
  if (existingCount > 0) return;
  const settings = await getSettings();
  const accepted = await JobApplication.find({ jobId: job._id, status: 'accepted' });
  const paymentStatus = env.paymentsMode === 'mock' ? 'completed' : 'pending';
  for (const app of accepted) {
    const gross = job.pay;
    const commission = Math.round((gross * (settings.commissionPercent || 10)) / 100);
    const net = gross - commission;
    await Transaction.create({
      uniqueTxnId: uniqueTxnId(),
      jobId: job._id,
      fromUserId: job.posterId,
      toUserId: app.workerId,
      type: 'job_payout',
      gross,
      commission,
      net,
      paymentStatus,
    });
    await notifyUser(app.workerId, {
      title: 'Payment recorded',
      body: `Job completed. You earned ₹${net} (₹${commission} platform fee).`,
      type: 'earnings',
      data: { jobId: String(job._id) },
    });
  }
  await notifyUser(job.posterId, {
    title: 'Job completed',
    body: `${accepted.length} worker(s) payout recorded.`,
    type: 'job',
    data: { jobId: String(job._id) },
  });
}

async function updateJobStatus(job, status, actorId, isAdmin) {
  const allowed = ['accepted', 'started', 'in_progress', 'completed', 'cancelled'];
  if (!allowed.includes(status)) throw new AppError(400, 'Invalid status');
  const owner = String(job.posterId) === String(actorId);
  if (!owner && !isAdmin) throw new AppError(403, 'Not allowed');
  if (job.status === 'completed' && status !== 'completed') {
    throw new AppError(400, 'Completed job cannot change status');
  }
  if (status === 'cancelled') {
    job.status = 'cancelled';
    await job.save();
    return job;
  }
  if (job.status === 'draft' || job.status === 'cancelled') {
    throw new AppError(400, 'Publish the job before changing work status');
  }
  if (STATUS_FLOW.includes(status) && STATUS_FLOW.includes(job.status)) {
    const from = STATUS_FLOW.indexOf(job.status === 'open' ? 'accepted' : job.status);
    const to = STATUS_FLOW.indexOf(status);
    if (job.status === 'open' && status === 'accepted') {
      // ok
    } else if (from >= 0 && to < from) {
      throw new AppError(400, 'Cannot move job status backwards');
    }
  }
  job.status = status;
  await job.save();
  if (status === 'completed') await settleCompletedJob(job);

  const apps = await JobApplication.find({ jobId: job._id, status: 'accepted' });
  await Promise.all(
    apps.map((a) =>
      notifyUser(a.workerId, {
        title: 'Job status updated',
        body: `Job "${job.title}" is now ${status.replace('_', ' ')}.`,
        type: 'job',
        data: { jobId: String(job._id), status },
      })
    )
  );
  return job;
}

async function blockedSetFor(userId) {
  if (!userId) return new Set();
  const me = await User.findById(userId).select('blockedUsers');
  const blockedMe = await User.find({ blockedUsers: userId }).select('_id');
  const set = new Set((me?.blockedUsers || []).map(String));
  blockedMe.forEach((u) => set.add(String(u._id)));
  return set;
}

module.exports = {
  assertNoDuplicateJob,
  ensureChat,
  settleCompletedJob,
  updateJobStatus,
  blockedSetFor,
};
