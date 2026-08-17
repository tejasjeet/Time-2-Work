require('dotenv').config();
const http = require('http');
const fs = require('fs');
const path = require('path');
const { env } = require('./config/env');
const { connectDb } = require('./config/db');
const { createApp } = require('./app');
const { initSockets } = require('./sockets');

async function main() {
  const uploadDir = path.resolve(process.cwd(), env.uploadDir);
  if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

  const app = createApp();
  const server = http.createServer(app);
  initSockets(server);

  server.listen(env.port, '0.0.0.0', () => {
    console.log(`Time2Work API listening on 0.0.0.0:${env.port}`);
  });

  await connectDb();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
