const mongoose = require('mongoose');

const ratingSchema = new mongoose.Schema(
  {
    jobId: { type: mongoose.Schema.Types.ObjectId, ref: 'Job', required: true },
    fromUserId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    toUserId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    stars: { type: Number, required: true, min: 1, max: 5 },
  },
  { timestamps: true, collection: 'ratings' }
);

ratingSchema.index({ jobId: 1, fromUserId: 1, toUserId: 1 }, { unique: true });
ratingSchema.index({ toUserId: 1, createdAt: -1 });

module.exports = mongoose.model('Rating', ratingSchema);
