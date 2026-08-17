const { Notification, User } = require('../models');
const { notificationDto } = require('./serializers');
const { emitToUser } = require('../sockets');
const { env } = require('../config/env');
const { getFirebaseAdmin } = require('./firebase');

async function notifyUser(userId, { title, body, type = 'general', data = {} }) {
  const doc = await Notification.create({ userId, title, body, type, data });
  const dto = notificationDto(doc);
  emitToUser(String(userId), 'notification', dto);
  pushFcm(userId, { title, body, data }).catch((err) => {
    console.warn('FCM send failed:', err.message);
  });
  return doc;
}

async function pushFcm(userId, { title, body, data }) {
  const user = await User.findById(userId).select('fcmTokens');
  const tokens = (user?.fcmTokens || []).filter(Boolean);
  if (!tokens.length) return;

  const admin = getFirebaseAdmin();
  if (admin) {
    const fb = require('firebase-admin');
    await fb.messaging().sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: Object.fromEntries(Object.entries(data || {}).map(([k, v]) => [k, String(v)])),
    });
    return;
  }

  if (env.fcmServerKey) {
    console.log('FCM (legacy key present) would send to', tokens.length, 'device(s):', title);
    return;
  }

  console.log('In-app only notification:', title, '→', String(userId));
}

module.exports = { notifyUser };
