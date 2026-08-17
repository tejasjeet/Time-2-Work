const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema(
  {
    orderId: { type: String, required: true, unique: true },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    jobId: { type: mongoose.Schema.Types.ObjectId, ref: 'Job' },
    type: { type: String, enum: ['job_fee', 'job_payout'], required: true },
    method: { type: String, enum: ['mock', 'razorpay'], required: true },
    amount: { type: Number, required: true },
    status: { type: String, enum: ['created', 'paid', 'failed'], default: 'created', index: true },
    razorpayOrderId: { type: String, default: '' },
    razorpayPaymentId: { type: String, default: '' },
    raw: { type: mongoose.Schema.Types.Mixed },
  },
  { timestamps: true, collection: 'payments' }
);

paymentSchema.index({ createdAt: -1 });
paymentSchema.index({ jobId: 1, type: 1 });

module.exports = mongoose.model('Payment', paymentSchema);
