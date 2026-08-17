const mongoose = require('mongoose');

const categorySchema = new mongoose.Schema(
  {
    slug: { type: String, required: true, unique: true },
    name: { type: String, required: true },
    nameHi: { type: String, default: '' },
    icon: { type: String, default: '' },
    active: { type: Boolean, default: true },
    sortOrder: { type: Number, default: 0 },
  },
  { timestamps: true, collection: 'categories' }
);

categorySchema.index({ active: 1, sortOrder: 1 });

module.exports = mongoose.model('Category', categorySchema);
