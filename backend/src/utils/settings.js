const Settings = require('../models/Settings');
const { SETTINGS_DEFAULTS } = Settings;

let cache = { data: null, at: 0 };
const TTL_MS = 15_000;

async function getSettings() {
  if (cache.data && Date.now() - cache.at < TTL_MS) return cache.data;
  let doc = await Settings.findOne();
  if (!doc) doc = await Settings.create(SETTINGS_DEFAULTS);
  cache = { data: doc, at: Date.now() };
  return doc;
}

function clearSettingsCache() {
  cache = { data: null, at: 0 };
}

function settingsDto(doc) {
  return {
    jobPostingFee: doc.jobPostingFee,
    commissionPercent: doc.commissionPercent,
    referralReward: doc.referralReward,
    primaryRadiusKm: doc.primaryRadiusKm,
    secondaryRadiusKm: doc.secondaryRadiusKm,
  };
}

module.exports = { getSettings, clearSettingsCache, settingsDto, SETTINGS_DEFAULTS };
