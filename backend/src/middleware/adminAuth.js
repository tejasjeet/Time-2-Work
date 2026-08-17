const { AdminUser } = require('../models');
const { verifyAccessToken } = require('../utils/jwt');
const { AppError, asyncHandler } = require('../utils/errors');
const { extractToken } = require('./auth');

const requireAdmin = asyncHandler(async (req, res, next) => {
  const token = extractToken(req);
  if (!token) throw new AppError(401, 'Authentication required', 'UNAUTHORIZED');
  const payload = verifyAccessToken(token);
  if (payload.kind !== 'admin' && payload.role !== 'admin') {
    throw new AppError(403, 'Admin only', 'FORBIDDEN');
  }
  const admin = await AdminUser.findById(payload.sub);
  if (!admin) throw new AppError(401, 'Invalid admin token', 'UNAUTHORIZED');
  req.user = { id: String(admin._id), role: 'admin', kind: 'admin', email: admin.email };
  req.admin = admin;
  next();
});

module.exports = { requireAdmin };
