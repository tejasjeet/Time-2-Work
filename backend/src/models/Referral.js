const mongoose = require('mongoose');

const referralSchema = new mongoose.Schema(
  {
    referrerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    referredId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    code: { type: String, required: true, unique: true },
    status: { type: String, enum: ['pending', 'completed', 'paid'], default: 'pending' },
    reward: { type: Number, default: 0 },
  },
  { timestamps: true, collection: 'referrals' }
);

referralSchema.index({ referrerId: 1 });

module.exports = mongoose.model('Referral', referralSchema);
