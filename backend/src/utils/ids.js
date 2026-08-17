const crypto = require('crypto');

function uniqueTxnId() {
  return `T2W${Date.now()}${crypto.randomBytes(3).toString('hex').toUpperCase()}`;
}

function orderId() {
  return `ORD${Date.now()}${crypto.randomBytes(3).toString('hex').toUpperCase()}`;
}

module.exports = { uniqueTxnId, orderId };
