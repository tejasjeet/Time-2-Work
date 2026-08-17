const path = require('path');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const { env } = require('./config/env');
const { errorHandler, notFound } = require('./middleware/errorHandler');
const { handleRazorpayWebhook } = require('./routes/payments');

const authRoutes = require('./routes/auth');
const usersRoutes = require('./routes/users');
const profilesRoutes = require('./routes/profiles');
const jobsRoutes = require('./routes/jobs');
const applicationsRoutes = require('./routes/applications');
const chatsRoutes = require('./routes/chats');
const paymentsRoutes = require('./routes/payments');
const { earningsRouter, transactionsRouter } = require('./routes/earnings');
const notificationsRoutes = require('./routes/notifications');
const categoriesRoutes = require('./routes/categories');
const searchRoutes = require('./routes/search');
const placesRoutes = require('./routes/places');
const servicesRoutes = require('./routes/services');
const marketplaceRoutes = require('./routes/marketplace');
const uploadsRoutes = require('./routes/uploads');
const sosRoutes = require('./routes/sos');
const adminRoutes = require('./routes/admin');

function createApp() {
  const app = express();
  app.set('trust proxy', 1);

  app.use(helmet());
  app.use(
    cors({
      origin: env.isProd ? env.corsOrigin : true,
      credentials: true,
    })
  );
  app.use(morgan(env.isProd ? 'combined' : 'dev'));

  app.post(
    '/api/payments/razorpay/webhook',
    express.raw({ type: 'application/json' }),
    (req, res, next) => handleRazorpayWebhook(req, res).catch(next)
  );

  app.use(express.json({ limit: '2mb' }));
  app.use(express.urlencoded({ extended: true }));

  const apiLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 300,
    standardHeaders: true,
    legacyHeaders: false,
  });
  app.use('/api', apiLimiter);

  const uploadPath = path.resolve(process.cwd(), env.uploadDir);
  app.use('/uploads', express.static(uploadPath));

  app.get('/health', (req, res) => {
    res.json({ ok: true, service: 'time2work-api', env: env.nodeEnv });
  });

  app.use('/api/auth', authRoutes);
  app.use('/api/users', usersRoutes);
  app.use('/api/profiles', profilesRoutes);
  app.use('/api/jobs', jobsRoutes);
  app.use('/api/applications', applicationsRoutes);
  app.use('/api/chats', chatsRoutes);
  app.use('/api/payments', paymentsRoutes);
  app.use('/api/earnings', earningsRouter);
  app.use('/api/transactions', transactionsRouter);
  app.use('/api/notifications', notificationsRoutes);
  app.use('/api/categories', categoriesRoutes);
  app.use('/api/search', searchRoutes);
  app.use('/api/places', placesRoutes);
  app.use('/api/services', servicesRoutes);
  app.use('/api/marketplace', marketplaceRoutes);
  app.use('/api/uploads', uploadsRoutes);
  app.use('/api/sos', sosRoutes);
  app.use('/api/admin', adminRoutes);

  app.use(notFound);
  app.use(errorHandler);
  return app;
}

module.exports = { createApp };
