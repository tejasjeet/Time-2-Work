const mongoose = require('mongoose');

const JOB_STATUSES = [
  'draft',
  'open',
  'accepted',
  'started',
  'in_progress',
  'completed',
  'cancelled',
];

const jobSchema = new mongoose.Schema(
  {
    posterId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    title: { type: String, required: true },
    description: { type: String, default: '' },
    category: { type: String, required: true, index: true },
    pay: { type: Number, required: true, min: 0 },
    payType: { type: String, enum: ['fixed', 'hourly', 'daily'], default: 'fixed' },
    workersRequired: { type: Number, default: 1, min: 1 },
    date: { type: Date, default: Date.now },
    timeSlot: { type: String, default: '' },
    location: {
      type: { type: String, enum: ['Point'] },
      coordinates: { type: [Number] },
    },
    address: { type: String, default: '' },
    status: { type: String, enum: JOB_STATUSES, default: 'draft', index: true },
    feePaid: { type: Boolean, default: false },
    feePaymentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Payment' },
    postingFee: { type: Number, default: 19 },
    posterRating: { type: Number, default: 0 },
    isSeed: { type: Boolean, default: false },
  },
  { timestamps: true, collection: 'jobs' }
);

jobSchema.index({ location: '2dsphere' });
jobSchema.index({ status: 1, category: 1, createdAt: -1 });
jobSchema.index({ posterId: 1, createdAt: -1 });

module.exports = mongoose.model('Job', jobSchema);
module.exports.JOB_STATUSES = JOB_STATUSES;
