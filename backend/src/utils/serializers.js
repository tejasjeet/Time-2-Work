const { toLatLng } = require('./geo');

function idOf(doc) {
  if (!doc) return null;
  return String(doc._id || doc.id);
}

function publicUser(user, { includeLocation = false } = {}) {
  if (!user) return null;
  const out = {
    id: idOf(user),
    name: user.name || '',
    photoUrl: user.photoUrl || '',
    role: user.role || null,
    about: user.about || '',
    avgRating: user.avgRating || 0,
    ratingCount: user.ratingCount || 0,
    verified: Boolean(user.verified),
    status: user.status || 'active',
    availableNow: user.availableNow,
  };
  if (includeLocation) {
    out.location = toLatLng(user.location);
    out.address = user.address || '';
  }
  return out;
}

function meUser(user) {
  if (!user) return null;
  return {
    ...publicUser(user, { includeLocation: true }),
    phone: user.phone,
    createdAt: user.createdAt,
  };
}

function publicAdmin(admin) {
  return {
    id: idOf(admin),
    email: admin.email,
    name: admin.name,
    role: 'admin',
  };
}

function jobDto(job, extras = {}) {
  const poster = job.poster || job.posterId;
  return {
    id: idOf(job),
    title: job.title,
    description: job.description,
    category: job.category,
    pay: job.pay,
    payType: job.payType,
    workersRequired: job.workersRequired,
    date: job.date,
    timeSlot: job.timeSlot || '',
    address: job.address || '',
    location: toLatLng(job.location),
    status: job.status,
    feePaid: Boolean(job.feePaid),
    postingFee: job.postingFee,
    poster: poster && poster.name !== undefined ? publicUser(poster) : poster ? { id: idOf(poster) } : null,
    posterRating: job.posterRating || (poster && poster.avgRating) || 0,
    distanceMeters: job.distance != null ? Math.round(job.distance) : extras.distanceMeters,
    createdAt: job.createdAt,
    ...extras,
  };
}

function applicationDto(app) {
  const worker = app.worker || app.workerId;
  const job = app.job || app.jobId;
  return {
    id: idOf(app),
    jobId: idOf(job),
    job: job && job.title !== undefined ? jobDto(job) : null,
    worker: worker && worker.name !== undefined ? publicUser(worker) : worker ? { id: idOf(worker) } : null,
    status: app.status,
    message: app.message || '',
    createdAt: app.createdAt,
  };
}

function chatDto(chat) {
  return {
    id: idOf(chat),
    jobId: idOf(chat.jobId),
    applicationId: chat.applicationId ? idOf(chat.applicationId) : null,
    participants: (chat.participants || []).map((p) =>
      p && p.name !== undefined ? publicUser(p) : { id: idOf(p) }
    ),
    lastMessage: chat.lastMessage || '',
    lastMessageAt: chat.lastMessageAt,
    createdAt: chat.createdAt,
  };
}

function messageDto(msg) {
  const sender = msg.sender || msg.senderId;
  return {
    id: idOf(msg),
    chatId: idOf(msg.chatId),
    sender: sender && sender.name !== undefined ? publicUser(sender) : { id: idOf(sender) },
    text: msg.text || '',
    imageUrl: msg.imageUrl || '',
    videoUrl: msg.videoUrl || '',
    createdAt: msg.createdAt,
  };
}

function transactionDto(txn) {
  return {
    id: idOf(txn),
    uniqueTxnId: txn.uniqueTxnId,
    jobId: idOf(txn.jobId),
    fromUserId: txn.fromUserId ? idOf(txn.fromUserId) : null,
    toUserId: txn.toUserId ? idOf(txn.toUserId) : null,
    type: txn.type,
    gross: txn.gross,
    commission: txn.commission,
    net: txn.net,
    paymentStatus: txn.paymentStatus,
    createdAt: txn.createdAt,
  };
}

function paymentDto(p) {
  return {
    id: idOf(p),
    orderId: p.orderId,
    type: p.type,
    method: p.method,
    amount: p.amount,
    status: p.status,
    jobId: p.jobId ? idOf(p.jobId) : null,
    razorpayOrderId: p.razorpayOrderId || null,
    createdAt: p.createdAt,
  };
}

function notificationDto(n) {
  return {
    id: idOf(n),
    title: n.title,
    body: n.body,
    type: n.type,
    data: n.data || {},
    read: Boolean(n.read),
    createdAt: n.createdAt,
  };
}

function reviewDto(r) {
  const from = r.fromUser || r.fromUserId;
  return {
    id: idOf(r),
    jobId: r.jobId ? idOf(r.jobId) : null,
    fromUser: from && from.name !== undefined ? publicUser(from) : { id: idOf(from) },
    stars: r.stars,
    review: r.review || r.text || '',
    createdAt: r.createdAt,
  };
}

module.exports = {
  idOf,
  publicUser,
  meUser,
  publicAdmin,
  jobDto,
  applicationDto,
  chatDto,
  messageDto,
  transactionDto,
  paymentDto,
  notificationDto,
  reviewDto,
};
