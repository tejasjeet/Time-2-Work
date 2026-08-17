const { ZodError } = require('zod');
const { env } = require('../config/env');

function errorHandler(err, req, res, next) {
  if (res.headersSent) return next(err);

  if (err instanceof ZodError) {
    const message = err.errors?.[0]?.message || 'Validation error';
    return res.status(400).json({ error: { message, code: 'VALIDATION_ERROR', details: err.errors } });
  }

  if (err.name === 'ValidationError') {
    return res.status(400).json({ error: { message: err.message, code: 'VALIDATION_ERROR' } });
  }

  if (err.code === 11000) {
    return res.status(409).json({ error: { message: 'Duplicate record', code: 'DUPLICATE' } });
  }

  if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
    return res.status(401).json({ error: { message: 'Invalid or expired token', code: 'UNAUTHORIZED' } });
  }

  const status = err.status || err.statusCode || 500;
  const payload = {
    error: {
      message: status === 500 && env.isProd ? 'Internal server error' : err.message || 'Error',
      code: err.code || (status === 500 ? 'INTERNAL' : 'ERROR'),
    },
  };
  if (!env.isProd && err.stack) payload.error.stack = err.stack;
  res.status(status).json(payload);
}

function notFound(req, res) {
  res.status(404).json({ error: { message: `Not found: ${req.method} ${req.path}`, code: 'NOT_FOUND' } });
}

module.exports = { errorHandler, notFound };
