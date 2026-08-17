const mongoose = require('mongoose');

const reportSchema = new mongoose.Schema(
  {
    reporterId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    targetType: { type: String, enum: ['user', 'job', 'sos'], required: true },
    targetId: { type: mongoose.Schema.Types.ObjectId },
    reason: { type: String, required: true },
    details: { type: String, default: '' },
    status: { type: String, enum: ['open', 'reviewed', 'resolved', 'dismissed'], default: 'open', index: true },
    adminNote: { type: String, default: '' },
  },
  { timestamps: true, collection: 'reports' }
);

reportSchema.index({ createdAt: -1 });
reportSchema.index({ targetType: 1, targetId: 1 });

module.exports = mongoose.model('Report', reportSchema);
