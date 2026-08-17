require('dotenv').config();

function bool(value, fallback = false) {
  if (value === undefined || value === null || value === '') return fallback;
  return String(value).toLowerCase() === 'true' || value === '1';
}

const isProd = process.env.NODE_ENV === 'production';

const env = {
  nodeEnv: process.env.NODE_ENV || 'development',
  isProd,
  port: Number(process.env.PORT) || 4000,
  mongoUri:
    process.env.MONGO_URI ||
    (isProd ? '' : 'mongodb://127.0.0.1:27017/time2work'),
  corsOrigin: (process.env.CORS_ORIGIN || 'http://localhost:3000,http://localhost:4000')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean),
  jwtSecret: process.env.JWT_SECRET || 'dev-access-secret',
  jwtRefreshSecret: process.env.JWT_REFRESH_SECRET || 'dev-refresh-secret',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  jwtRefreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d',
  mockOtp: bool(process.env.MOCK_OTP, !isProd),
  firebaseEnabled: bool(process.env.FIREBASE_ENABLED, false),
  firebaseProjectId: process.env.FIREBASE_PROJECT_ID || '',
  firebaseClientEmail: process.env.FIREBASE_CLIENT_EMAIL || '',
  firebasePrivateKey: (process.env.FIREBASE_PRIVATE_KEY || '').replace(/\\n/g, '\n'),
  paymentsMode: process.env.PAYMENTS_MODE || (isProd ? 'razorpay' : 'mock'),
  razorpayKeyId: process.env.RAZORPAY_KEY_ID || '',
  razorpayKeySecret: process.env.RAZORPAY_KEY_SECRET || '',
  razorpayWebhookSecret: process.env.RAZORPAY_WEBHOOK_SECRET || '',
  fcmServerKey: process.env.FCM_SERVER_KEY || '',
  uploadDir: process.env.UPLOAD_DIR || 'uploads',
  publicUrl:
    process.env.PUBLIC_URL ||
    process.env.RENDER_EXTERNAL_URL ||
    (process.env.RAILWAY_PUBLIC_DOMAIN
      ? `https://${process.env.RAILWAY_PUBLIC_DOMAIN}`
      : 'http://localhost:4000'),
  googleMapsApiKey: process.env.GOOGLE_MAPS_API_KEY || '',
};

module.exports = { env };
