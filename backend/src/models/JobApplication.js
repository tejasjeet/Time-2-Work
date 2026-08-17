const mongoose = require('mongoose');

const APP_STATUSES = ['applied', 'shortlisted', 'accepted', 'rejected', 'cancelled'];

const jobApplicationSchema = new mongoose.Schema(
  {
    jobId: { type: mongoose.Schema.Types.ObjectId, ref: 'Job', required: true },
    workerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    status: { type: String, enum: APP_STATUSES, default: 'applied', index: true },
    message: { type: String, default: '' },
  },
  { timestamps: true, collection: 'job_applications' }
);

jobApplicationSchema.index({ jobId: 1, workerId: 1 }, { unique: true });
jobApplicationSchema.index({ workerId: 1, createdAt: -1 });
jobApplicationSchema.index({ jobId: 1, status: 1 });

module.exports = mongoose.model('JobApplication', jobApplicationSchema);
module.exports.APP_STATUSES = APP_STATUSES;
