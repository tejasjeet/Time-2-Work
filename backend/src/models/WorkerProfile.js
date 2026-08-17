const mongoose = require('mongoose');

const workerProfileSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', unique: true, required: true },
    skills: { type: [String], default: [] },
    experienceYears: { type: Number, default: 0 },
    availableNow: { type: Boolean, default: true },
    hourlyRate: { type: Number, default: 0 },
    bio: { type: String, default: '' },
    languages: { type: [String], default: ['hi', 'en'] },
  },
  { timestamps: true, collection: 'worker_profiles' }
);

workerProfileSchema.index({ skills: 1 });
workerProfileSchema.index({ availableNow: 1 });

module.exports = mongoose.model('WorkerProfile', workerProfileSchema);
