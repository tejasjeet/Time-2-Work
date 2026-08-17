const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema(
  {
    uniqueTxnId: { type: String, required: true, unique: true },
    jobId: { type: mongoose.Schema.Types.ObjectId, ref: 'Job' },
    fromUserId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    toUserId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', index: true },
    type: { type: String, enum: ['job_payout', 'job_fee', 'refund'], required: true },
    gross: { type: Number, required: true },
    commission: { type: Number, default: 0 },
    net: { type: Number, required: true },
    paymentStatus: { type: String, enum: ['pending', 'completed', 'failed'], default: 'pending', index: true },
  },
  { timestamps: true, collection: 'transactions' }
);

transactionSchema.index({ toUserId: 1, createdAt: -1 });
transactionSchema.index({ jobId: 1, type: 1 });
transactionSchema.index({ createdAt: -1 });

module.exports = mongoose.model('Transaction', transactionSchema);
