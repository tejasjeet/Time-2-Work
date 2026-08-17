const mongoose = require('mongoose');

const serviceSchema = new mongoose.Schema(
  {
    providerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    title: { type: String, required: true },
    category: { type: String, default: '' },
    description: { type: String, default: '' },
    price: { type: Number, default: 0 },
    location: {
      type: { type: String, enum: ['Point'] },
      coordinates: { type: [Number] },
    },
    address: { type: String, default: '' },
    active: { type: Boolean, default: true },
  },
  { timestamps: true, collection: 'services' }
);

serviceSchema.index({ location: '2dsphere' });
serviceSchema.index({ category: 1, createdAt: -1 });

module.exports = mongoose.model('Service', serviceSchema);
