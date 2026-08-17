const { Payment, Job, Transaction } = require('../models');
const { env } = require('../config/env');
const { AppError } = require('../utils/errors');
const { orderId, uniqueTxnId } = require('../utils/ids');
const { getSettings } = require('../utils/settings');
const { getRazorpay } = require('../utils/razorpay');
const { notifyUser } = require('../utils/notify');

async function createOrder({ userId, type, jobId, method }) {
  const settings = await getSettings();
  const job = jobId ? await Job.findById(jobId) : null;
  if (jobId && !job) throw new AppError(404, 'Job not found');

  let amount = 0;
  if (type === 'job_fee') {
    if (!job) throw new AppError(400, 'jobId required for job_fee');
    if (String(job.posterId) !== String(userId)) throw new AppError(403, 'Not the job owner');
    if (job.feePaid) throw new AppError(400, 'Posting fee already paid');
    amount = job.postingFee || settings.jobPostingFee;
  } else if (type === 'job_payout') {
    if (!job) throw new AppError(400, 'jobId required for job_payout');
    amount = job.pay;
  } else {
    throw new AppError(400, 'Invalid payment type');
  }

  const useMethod = method || (env.paymentsMode === 'razorpay' ? 'razorpay' : 'mock');
  const payment = await Payment.create({
    orderId: orderId(),
    userId,
    jobId: job?._id,
    type,
    method: useMethod,
    amount,
    status: 'created',
  });

  if (useMethod === 'razorpay') {
    const rz = getRazorpay();
    if (!rz) throw new AppError(501, 'Razorpay is not configured');
    const rzOrder = await rz.orders.create({
      amount: Math.round(amount * 100),
      currency: 'INR',
      receipt: payment.orderId,
      notes: { type, jobId: job ? String(job._id) : '', paymentId: String(payment._id) },
    });
    payment.razorpayOrderId = rzOrder.id;
    payment.raw = rzOrder;
    await payment.save();
  }

  return payment;
}

async function markPaid(payment) {
  if (payment.status === 'paid') return payment;
  payment.status = 'paid';
  await payment.save();

  if (payment.type === 'job_fee' && payment.jobId) {
    const job = await Job.findById(payment.jobId);
    if (job) {
      job.feePaid = true;
      job.feePaymentId = payment._id;
      await job.save();
    }
    await Transaction.create({
      uniqueTxnId: uniqueTxnId(),
      jobId: payment.jobId,
      fromUserId: payment.userId,
      type: 'job_fee',
      gross: payment.amount,
      commission: 0,
      net: payment.amount,
      paymentStatus: 'completed',
    });
    await notifyUser(payment.userId, {
      title: 'Posting fee paid',
      body: `₹${payment.amount} posting fee received. You can publish the job.`,
      type: 'payment',
      data: { jobId: String(payment.jobId), orderId: payment.orderId },
    });
  }

  return payment;
}

async function confirmByOrderId(orderIdValue) {
  const payment = await Payment.findOne({ orderId: orderIdValue });
  if (!payment) throw new AppError(404, 'Order not found');
  return markPaid(payment);
}

module.exports = { createOrder, markPaid, confirmByOrderId };
