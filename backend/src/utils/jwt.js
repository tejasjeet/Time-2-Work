const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { env } = require('../config/env');

function signAccessToken(payload) {
  return jwt.sign({ ...payload, typ: 'access' }, env.jwtSecret, {
    expiresIn: env.jwtExpiresIn,
  });
}

function signRefreshToken(payload) {
  return jwt.sign({ ...payload, typ: 'refresh' }, env.jwtRefreshSecret, {
    expiresIn: env.jwtRefreshExpiresIn,
  });
}

function verifyAccessToken(token) {
  return jwt.verify(token, env.jwtSecret);
}

function verifyRefreshToken(token) {
  return jwt.verify(token, env.jwtRefreshSecret);
}

function hashToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

function issueUserTokens(user) {
  const payload = { sub: String(user._id), role: user.role || 'user', kind: 'user' };
  const token = signAccessToken(payload);
  const refreshToken = signRefreshToken(payload);
  return { token, refreshToken };
}

function issueAdminTokens(admin) {
  const payload = { sub: String(admin._id), role: 'admin', kind: 'admin' };
  const token = signAccessToken(payload);
  const refreshToken = signRefreshToken(payload);
  return { token, refreshToken };
}

module.exports = {
  signAccessToken,
  signRefreshToken,
  verifyAccessToken,
  verifyRefreshToken,
  hashToken,
  issueUserTokens,
  issueAdminTokens,
};
