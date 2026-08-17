require('dotenv').config();
const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');
const { env } = require('../config/env');
const {
  User,
  WorkerProfile,
  BusinessProfile,
  Job,
  JobApplication,
  Category,
  Chat,
  Message,
  Transaction,
  Payment,
  Rating,
  Review,
  Notification,
  AdminUser,
  Settings,
  Service,
  MarketplaceListing,
} = require('../models');
const { SETTINGS_DEFAULTS } = require('../models/Settings');
const { uniqueTxnId } = require('../utils/ids');
const categories = require('./categories');

const MUMBAI = { lat: 19.076, lng: 72.8777 };

function geo(lat, lng) {
  return { type: 'Point', coordinates: [lng, lat] };
}

async function upsertUser(phone, fields) {
  return User.findOneAndUpdate(
    { phone },
    { $set: { ...fields, phone, isSeed: true } },
    { new: true, upsert: true }
  );
}

async function seed() {
  await mongoose.connect(env.mongoUri);
  console.log('Seeding Time2Work…', env.mongoUri);

  await Settings.findOneAndUpdate({}, { $setOnInsert: SETTINGS_DEFAULTS }, { upsert: true, new: true });

  for (const c of categories) {
    await Category.findOneAndUpdate({ slug: c.slug }, { $set: { ...c, active: true } }, { upsert: true });
  }
  console.log(`Categories: ${categories.length}`);

  const adminHash = await bcrypt.hash('Admin@123', 10);
  await AdminUser.findOneAndUpdate(
    { email: 'admin@time2work.com' },
    { $set: { email: 'admin@time2work.com', passwordHash: adminHash, name: 'Time2Work Admin', role: 'admin' } },
    { upsert: true }
  );
  console.log('Admin: admin@time2work.com / Admin@123');

  const worker = await upsertUser('9999990001', {
    name: 'Ravi Kumar',
    role: 'worker',
    about: 'Electrician & helper. Available across Mumbai.',
    address: 'Andheri East, Mumbai',
    location: geo(19.1136, 72.8697),
    status: 'active',
    verified: true,
    avgRating: 4.6,
    ratingCount: 8,
  });
  await WorkerProfile.findOneAndUpdate(
    { userId: worker._id },
    {
      $set: {
        userId: worker._id,
        skills: ['electrician', 'labour', 'ac-repair'],
        experienceYears: 5,
        availableNow: true,
        hourlyRate: 150,
        bio: 'Licensed electrician. House wiring, fans, inverters.',
        languages: ['hi', 'en', 'mr'],
      },
    },
    { upsert: true }
  );

  const business = await upsertUser('9999990002', {
    name: 'Amit Sharma',
    role: 'business',
    about: 'Sharma Contractors — painting, electrical, labour.',
    address: 'Bandra West, Mumbai',
    location: geo(19.0596, 72.8295),
    status: 'active',
    verified: true,
    avgRating: 4.4,
    ratingCount: 12,
  });
  await BusinessProfile.findOneAndUpdate(
    { userId: business._id },
    {
      $set: {
        userId: business._id,
        businessName: 'Sharma Contractors',
        category: 'labour',
        description: 'Local contractor for painting, electrical and loading work.',
        address: 'Bandra West, Mumbai',
      },
    },
    { upsert: true }
  );

  await Job.deleteMany({ isSeed: true });
  await JobApplication.deleteMany({
    workerId: worker._id,
  });
  await Chat.deleteMany({ participants: { $all: [worker._id, business._id] } });
  await Message.deleteMany({});
  await Transaction.deleteMany({ $or: [{ fromUserId: business._id }, { toUserId: worker._id }] });
  await Payment.deleteMany({ userId: business._id });
  await Rating.deleteMany({ $or: [{ fromUserId: business._id }, { fromUserId: worker._id }] });
  await Review.deleteMany({ $or: [{ fromUserId: business._id }, { fromUserId: worker._id }] });

  const samples = [
    {
      title: 'Need helper for loading boxes',
      description: 'Help load cartons at Bailey Road shop. 3 hours work.',
      category: 'loader',
      pay: 500,
      workersRequired: 2,
      lat: 25.610, lng: 85.130,
      address: 'Bailey Road, Patna',
      status: 'open',
    },
    {
      title: 'Electrician Needed',
      description: 'Wiring and switchboard repair in 2BHK flat.',
      category: 'electrician',
      pay: 700,
      workersRequired: 1,
      lat: 25.600, lng: 85.145,
      address: 'Boring Road, Patna',
      status: 'open',
    },
    {
      title: 'Painter for Home',
      description: 'Interior wall painting for 1 BHK.',
      category: 'painter',
      pay: 1200,
      workersRequired: 1,
      lat: 25.585, lng: 85.120,
      address: 'Kankarbagh, Patna',
      status: 'open',
    },
    {
      title: 'Delivery Partner',
      description: 'Evening food delivery partner needed.',
      category: 'delivery',
      pay: 450,
      workersRequired: 1,
      lat: 25.595, lng: 85.155,
      address: 'Fraser Road, Patna',
      status: 'open',
    },
    {
      title: 'Need 2 helpers for shop shifting',
      description: 'Packing and loading furniture from Andheri to Bandra. 4 hours.',
      category: 'loader',
      pay: 600,
      workersRequired: 2,
      lat: 19.119, lng: 72.846,
      address: 'Andheri West, Mumbai',
      status: 'open',
    },
    {
      title: 'House painting — 1 BHK',
      description: 'Interior painting, materials provided. Finish in 2 days.',
      category: 'painter',
      pay: 2500,
      workersRequired: 1,
      lat: 19.076, lng: 72.8777,
      address: 'Dadar East, Mumbai',
      status: 'open',
    },
    {
      title: 'Fan and switchboard repair',
      description: '3 ceiling fans not working. Need electrician today.',
      category: 'electrician',
      pay: 500,
      workersRequired: 1,
      lat: 19.089, lng: 72.865,
      address: 'Sion, Mumbai',
      status: 'open',
    },
    {
      title: 'Kitchen plumbing leak',
      description: 'Sink pipe leaking. Urgent, evening slot.',
      category: 'plumber',
      pay: 400,
      workersRequired: 1,
      lat: 19.065, lng: 72.89,
      address: 'Kurla, Mumbai',
      status: 'open',
    },
    {
      title: 'Warehouse loading — 8 AM',
      description: 'Unload 2 tempos. Daily wage.',
      category: 'warehouse',
      pay: 700,
      payType: 'daily',
      workersRequired: 3,
      lat: 19.1, lng: 72.91,
      address: 'Chembur industrial area',
      status: 'open',
    },
    {
      title: 'Event setup staff (draft)',
      description: 'Chairs and stage setup. Will publish after fee.',
      category: 'event-staff',
      pay: 800,
      workersRequired: 2,
      lat: 19.072, lng: 72.86,
      address: 'Worli, Mumbai',
      status: 'draft',
      feePaid: false,
    },
  ];

  const createdJobs = [];
  for (const s of samples) {
    const job = await Job.create({
      posterId: business._id,
      title: s.title,
      description: s.description,
      category: s.category,
      pay: s.pay,
      payType: s.payType || 'fixed',
      workersRequired: s.workersRequired,
      date: new Date(),
      timeSlot: '09:00-18:00',
      location: geo(s.lat, s.lng),
      address: s.address,
      status: s.status,
      feePaid: s.status !== 'draft',
      postingFee: 19,
      posterRating: business.avgRating,
      isSeed: true,
    });
    createdJobs.push(job);
    if (s.status !== 'draft') {
      await Payment.create({
        orderId: `SEEDFEE${job._id}`,
        userId: business._id,
        jobId: job._id,
        type: 'job_fee',
        method: 'mock',
        amount: 19,
        status: 'paid',
      });
    }
  }

  const applyJob = createdJobs.find((j) => j.category === 'electrician');
  const completedJob = await Job.create({
    posterId: business._id,
    title: 'Completed: inverter wiring',
    description: 'Seed completed job for earnings demo.',
    category: 'electrician',
    pay: 800,
    payType: 'fixed',
    workersRequired: 1,
    date: new Date(Date.now() - 2 * 24 * 3600 * 1000),
    timeSlot: '10:00-14:00',
    location: geo(MUMBAI.lat, MUMBAI.lng),
    address: 'Parel, Mumbai',
    status: 'completed',
    feePaid: true,
    postingFee: 19,
    posterRating: business.avgRating,
    isSeed: true,
  });

  const acceptedApp = await JobApplication.create({
    jobId: completedJob._id,
    workerId: worker._id,
    status: 'accepted',
    message: 'I Can Do It',
  });
  await JobApplication.create({
    jobId: applyJob._id,
    workerId: worker._id,
    status: 'applied',
    message: 'Available today after 2 PM',
  });

  const chat = await Chat.create({
    jobId: completedJob._id,
    applicationId: acceptedApp._id,
    participants: [business._id, worker._id],
    lastMessage: 'Thanks, work looks good.',
    lastMessageAt: new Date(),
  });
  await Message.create({
    chatId: chat._id,
    senderId: business._id,
    text: 'Please come at 10 AM. Do not share phone on chat.',
  });
  await Message.create({
    chatId: chat._id,
    senderId: worker._id,
    text: 'On my way. Will update here.',
  });
  await Message.create({
    chatId: chat._id,
    senderId: business._id,
    text: 'Thanks, work looks good.',
  });

  const commission = 80;
  await Transaction.create({
    uniqueTxnId: uniqueTxnId(),
    jobId: completedJob._id,
    fromUserId: business._id,
    toUserId: worker._id,
    type: 'job_payout',
    gross: 800,
    commission,
    net: 720,
    paymentStatus: 'completed',
  });

  await Rating.create({
    jobId: completedJob._id,
    fromUserId: business._id,
    toUserId: worker._id,
    stars: 5,
  });
  await Review.create({
    jobId: completedJob._id,
    fromUserId: business._id,
    toUserId: worker._id,
    stars: 5,
    review: 'On time and neat wiring.',
  });

  await Notification.create({
    userId: worker._id,
    title: 'Welcome to Time2Work',
    body: 'Nearby jobs in 5 KM are ready. Tap I Can Do It to apply.',
    type: 'system',
  });
  await Notification.create({
    userId: business._id,
    title: 'Job posted',
    body: 'Your sample jobs are live around Mumbai.',
    type: 'job',
  });

  const serviceSeeds = [
    {
      filter: { providerId: worker._id, title: 'Home electrical visit' },
      data: {
        providerId: worker._id,
        title: 'Home electrical visit',
        category: 'electrician',
        description: 'Switch, fan, and wiring repair at your doorstep.',
        price: 299,
        location: geo(19.1136, 72.8697),
        address: 'Andheri East, Mumbai',
        active: true,
      },
    },
    {
      filter: { providerId: worker._id, title: 'AC service & gas refill' },
      data: {
        providerId: worker._id,
        title: 'AC service & gas refill',
        category: 'ac-repair',
        description: 'Split AC deep clean, cooling check, and gas top-up.',
        price: 499,
        location: geo(19.076, 72.8777),
        address: 'Dadar, Mumbai',
        active: true,
      },
    },
    {
      filter: { providerId: worker._id, title: 'Home deep cleaning' },
      data: {
        providerId: worker._id,
        title: 'Home deep cleaning',
        category: 'cleaning',
        description: '2BHK kitchen, bathroom, and floor cleaning with supplies.',
        price: 899,
        location: geo(19.089, 72.865),
        address: 'Sion, Mumbai',
        active: true,
      },
    },
    {
      filter: { providerId: worker._id, title: 'Plumbing repair visit' },
      data: {
        providerId: worker._id,
        title: 'Plumbing repair visit',
        category: 'plumber',
        description: 'Leak fix, tap replacement, and blockage removal.',
        price: 249,
        location: geo(19.065, 72.89),
        address: 'Kurla, Mumbai',
        active: true,
      },
    },
  ];

  for (const s of serviceSeeds) {
    await Service.findOneAndUpdate(s.filter, { $set: s.data }, { upsert: true });
  }

  const bazarSeeds = [
    {
      filter: { sellerId: business._id, title: 'Used drill machine' },
      data: {
        sellerId: business._id,
        title: 'Used drill machine',
        description: '1-year-old Bosch drill with 2 bits. Works perfectly.',
        price: 1500,
        category: 'tools',
        location: geo(19.0596, 72.8295),
        address: 'Bandra West',
        status: 'active',
        images: ['https://images.unsplash.com/photo-1504148455328-c376907a0c12?w=600'],
      },
    },
    {
      filter: { sellerId: business._id, title: 'City cycle — good condition' },
      data: {
        sellerId: business._id,
        title: 'City cycle — good condition',
        description: 'Hero sprint bike, recently serviced, negotiable.',
        price: 2800,
        category: 'vehicles',
        location: geo(19.119, 72.846),
        address: 'Andheri West',
        status: 'active',
        images: ['https://images.unsplash.com/photo-1485965120180-e8f993113851?w=600'],
      },
    },
    {
      filter: { sellerId: business._id, title: 'Study table with chair' },
      data: {
        sellerId: business._id,
        title: 'Study table with chair',
        description: 'Wooden table + chair set. Pickup only.',
        price: 2200,
        category: 'furniture',
        location: geo(19.076, 72.8777),
        address: 'Dadar East',
        status: 'active',
        images: ['https://images.unsplash.com/photo-1518455027359-5f4d6c2f4753?w=600'],
      },
    },
    {
      filter: { sellerId: business._id, title: 'Android phone 128GB' },
      data: {
        sellerId: business._id,
        title: 'Android phone 128GB',
        description: 'Redmi Note series, battery health 87%, box included.',
        price: 8500,
        category: 'electronics',
        location: geo(19.1, 72.91),
        address: 'Chembur',
        status: 'active',
        images: ['https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=600'],
      },
    },
    {
      filter: { sellerId: business._id, title: 'Mixer grinder — Preethi' },
      data: {
        sellerId: business._id,
        title: 'Mixer grinder — Preethi',
        description: '3 jars, used 8 months, moving sale.',
        price: 1800,
        category: 'electronics',
        location: geo(25.5941, 85.1376),
        address: 'Boring Road, Patna',
        status: 'active',
        images: ['https://images.unsplash.com/photo-1585515320310-259814833e62?w=600'],
      },
    },
    {
      filter: { sellerId: business._id, title: 'Sofa set 3+1+1' },
      data: {
        sellerId: business._id,
        title: 'Sofa set 3+1+1',
        description: 'Fabric sofa, light use, buyer arranges transport.',
        price: 12000,
        category: 'furniture',
        location: geo(19.072, 72.86),
        address: 'Worli',
        status: 'active',
        images: ['https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=600'],
      },
    },
    {
      filter: { sellerId: business._id, title: 'Engineering books bundle' },
      data: {
        sellerId: business._id,
        title: 'Engineering books bundle',
        description: '10 books — mechanics, maths, and drawing.',
        price: 600,
        category: 'other',
        location: geo(25.61, 85.13),
        address: 'Bailey Road, Patna',
        status: 'active',
        images: ['https://images.unsplash.com/photo-1524995998252-8014e131ced7?w=600'],
      },
    },
    {
      filter: { sellerId: business._id, title: 'Hammer & toolkit set' },
      data: {
        sellerId: business._id,
        title: 'Hammer & toolkit set',
        description: '16-piece home repair kit with carry box.',
        price: 750,
        category: 'tools',
        location: geo(25.585, 85.12),
        address: 'Kankarbagh, Patna',
        status: 'active',
        images: ['https://images.unsplash.com/photo-1530124566582-793957699588?w=600'],
      },
    },
  ];

  for (const b of bazarSeeds) {
    await MarketplaceListing.findOneAndUpdate(b.filter, { $set: b.data }, { upsert: true });
  }

  await Promise.all(
    [
      User,
      WorkerProfile,
      BusinessProfile,
      Job,
      JobApplication,
      Category,
      Chat,
      Message,
      Transaction,
      Payment,
      Rating,
      Review,
      Notification,
      AdminUser,
      Settings,
      Service,
      MarketplaceListing,
    ].map((m) => m.syncIndexes())
  );

  console.log('Seed complete.');
  console.log('  Worker  9999990001  OTP 123456');
  console.log('  Business 9999990002  OTP 123456');
  console.log('  Admin   admin@time2work.com / Admin@123');
  console.log(`  Sample jobs near ${MUMBAI.lat}, ${MUMBAI.lng}`);
  await mongoose.disconnect();
}

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});
