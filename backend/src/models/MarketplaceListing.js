const mongoose = require('mongoose');

const marketplaceListingSchema = new mongoose.Schema(
  {
    sellerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    title: { type: String, required: true },
    description: { type: String, default: '' },
    price: { type: Number, default: 0 },
    images: { type: [String], default: [] },
    category: { type: String, default: '' },
    location: {
      type: { type: String, enum: ['Point'] },
      coordinates: { type: [Number] },
    },
    address: { type: String, default: '' },
    status: { type: String, enum: ['active', 'sold', 'hidden'], default: 'active', index: true },
  },
  { timestamps: true, collection: 'marketplace_listings' }
);

marketplaceListingSchema.index({ location: '2dsphere' });
marketplaceListingSchema.index({ category: 1, createdAt: -1 });

module.exports = mongoose.model('MarketplaceListing', marketplaceListingSchema);
