const mongoose = require('mongoose');

const businessProfileSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', unique: true, required: true },
    businessName: { type: String, default: '' },
    category: { type: String, default: '' },
    description: { type: String, default: '' },
    address: { type: String, default: '' },
    gstin: { type: String, default: '' },
  },
  { timestamps: true, collection: 'business_profiles' }
);

businessProfileSchema.index({ category: 1 });

module.exports = mongoose.model('BusinessProfile', businessProfileSchema);
