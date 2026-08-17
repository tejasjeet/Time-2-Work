const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema(
  {
    jobId: { type: mongoose.Schema.Types.ObjectId, ref: 'Job' },
    ratingId: { type: mongoose.Schema.Types.ObjectId, ref: 'Rating' },
    fromUserId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    toUserId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    stars: { type: Number, required: true, min: 1, max: 5 },
    review: { type: String, default: '' },
  },
  { timestamps: true, collection: 'reviews' }
);

reviewSchema.index({ toUserId: 1, createdAt: -1 });
reviewSchema.index({ jobId: 1 });

module.exports = mongoose.model('Review', reviewSchema);
