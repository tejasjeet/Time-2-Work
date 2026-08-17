const { User, AdminUser } = require('../models');
const { verifyAccessToken } = require('../utils/jwt');
const { AppError, asyncHandler } = require('../utils/errors');

function extractToken(req) {
  const header = req.headers.authorization || '';
  if (header.startsWith('Bearer ')) return header.slice(7);
  return req.query.token || null;
}

const requireAuth = asyncHandler(async (req, res, next) => {
  const token = extractToken(req);
  if (!token) throw new AppError(401, 'Authentication required', 'UNAUTHORIZED');
  const payload = verifyAccessToken(token);
  if (payload.kind === 'admin') {
    const admin = await AdminUser.findById(payload.sub);
    if (!admin) throw new AppError(401, 'Invalid token', 'UNAUTHORIZED');
    req.user = { id: String(admin._id), role: 'admin', kind: 'admin', email: admin.email };
    req.admin = admin;
    return next();
  }
  const user = await User.findById(payload.sub);
  if (!user) throw new AppError(401, 'Invalid token', 'UNAUTHORIZED');
  if (user.status === 'blocked' || user.status === 'suspended') {
    throw new AppError(403, `Account is ${user.status}`, 'ACCOUNT_DISABLED');
  }
  req.user = { id: String(user._id), role: user.role, kind: 'user' };
  req.authUser = user;
  next();
});

const optionalAuth = asyncHandler(async (req, res, next) => {
  const token = extractToken(req);
  if (!token) return next();
  try {
    const payload = verifyAccessToken(token);
    if (payload.kind === 'admin') {
      req.user = { id: payload.sub, role: 'admin', kind: 'admin' };
      return next();
    }
    const user = await User.findById(payload.sub);
    if (user && user.status === 'active') {
      req.user = { id: String(user._id), role: user.role, kind: 'user' };
      req.authUser = user;
    }
  } catch {
    // ignore invalid optional token
  }
  next();
});

function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.user) return next(new AppError(401, 'Authentication required', 'UNAUTHORIZED'));
    if (req.user.role === 'admin') return next();
    if (!roles.includes(req.user.role)) {
      return next(new AppError(403, 'Insufficient role', 'FORBIDDEN'));
    }
    next();
  };
}

module.exports = { requireAuth, optionalAuth, requireRole, extractToken };
