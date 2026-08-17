const mongoose = require('mongoose');
const { env } = require('./env');

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function connectDb() {
  if (!env.mongoUri) {
    throw new Error('MONGO_URI is not set. Add it in Render → Environment.');
  }

  mongoose.set('strictQuery', true);

  const options = {
    serverSelectionTimeoutMS: 20000,
    connectTimeoutMS: 20000,
    maxPoolSize: 10,
  };

  let lastError;
  for (let attempt = 1; attempt <= 5; attempt += 1) {
    try {
      await mongoose.connect(env.mongoUri, options);
      console.log(`MongoDB connected (attempt ${attempt})`);
      break;
    } catch (err) {
      lastError = err;
      console.error(`MongoDB connect attempt ${attempt} failed:`, err.message);
      if (attempt < 5) await sleep(attempt * 2000);
    }
  }

  if (mongoose.connection.readyState !== 1) {
    throw lastError || new Error('MongoDB connection failed');
  }

  // Do not block Render health checks on index sync.
  const models = require('../models');
  Promise.all(
    Object.values(models)
      .filter((m) => typeof m.syncIndexes === 'function')
      .map((m) => m.syncIndexes().catch((err) => console.warn('syncIndexes:', err.message)))
  ).then(() => console.log('MongoDB indexes synced'));
}

async function disconnectDb() {
  await mongoose.disconnect();
}

module.exports = { connectDb, disconnectDb };
