const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    phone: { type: String, unique: true, sparse: true },
    name: { type: String, default: '' },
    photoUrl: { type: String, default: '' },
    role: { type: String, enum: ['worker', 'business', null], default: null },
    location: {
      type: { type: String, enum: ['Point'] },
      coordinates: { type: [Number] },
    },
    address: { type: String, default: '' },
    about: { type: String, default: '' },
    status: { type: String, enum: ['active', 'suspended', 'blocked'], default: 'active', index: true },
    verified: { type: Boolean, default: false },
    fcmTokens: { type: [String], default: [] },
    blockedUsers: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    avgRating: { type: Number, default: 0 },
    ratingCount: { type: Number, default: 0 },
    refreshTokenHash: { type: String, default: '' },
    firebaseUid: { type: String, default: '' },
    isSeed: { type: Boolean, default: false },
  },
  { timestamps: true, collection: 'users' }
);

userSchema.index({ location: '2dsphere' });
userSchema.index({ createdAt: -1 });
userSchema.index({ role: 1, status: 1 });

module.exports = mongoose.model('User', userSchema);
