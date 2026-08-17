const mongoose = require('mongoose');
const { env } = require('./env');

async function connectDb() {
  mongoose.set('strictQuery', true);
  await mongoose.connect(env.mongoUri);
  const models = require('../models');
  await Promise.all(
    Object.values(models)
      .filter((m) => typeof m.syncIndexes === 'function')
      .map((m) => m.syncIndexes())
  );
  console.log('MongoDB connected');
}

async function disconnectDb() {
  await mongoose.disconnect();
}

module.exports = { connectDb, disconnectDb };
