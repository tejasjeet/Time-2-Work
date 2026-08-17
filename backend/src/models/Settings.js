const mongoose = require('mongoose');

const DEFAULTS = {
  jobPostingFee: 19,
  commissionPercent: 10,
  referralReward: 0,
  primaryRadiusKm: 5,
  secondaryRadiusKm: 10,
};

const settingsSchema = new mongoose.Schema(
  {
    jobPostingFee: { type: Number, default: DEFAULTS.jobPostingFee },
    commissionPercent: { type: Number, default: DEFAULTS.commissionPercent },
    referralReward: { type: Number, default: DEFAULTS.referralReward },
    primaryRadiusKm: { type: Number, default: DEFAULTS.primaryRadiusKm },
    secondaryRadiusKm: { type: Number, default: DEFAULTS.secondaryRadiusKm },
  },
  { timestamps: true, collection: 'settings' }
);

module.exports = mongoose.model('Settings', settingsSchema);
module.exports.SETTINGS_DEFAULTS = DEFAULTS;
