const path = require('path');
const fs = require('fs');
const express = require('express');
const multer = require('multer');
const { requireAuth } = require('../middleware/auth');
const { AppError, asyncHandler } = require('../utils/errors');
const { env } = require('../config/env');

const router = express.Router();

const uploadDir = path.resolve(process.cwd(), env.uploadDir);
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadDir),
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname || '') || (file.mimetype.startsWith('video/') ? '.mp4' : '.jpg');
    cb(null, `chat-${Date.now()}-${Math.random().toString(36).slice(2, 10)}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 25 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    if (file.mimetype.startsWith('image/') || file.mimetype.startsWith('video/')) {
      cb(null, true);
      return;
    }
    cb(new Error('Only images and videos are allowed'));
  },
});

router.post(
  '/chat',
  requireAuth,
  upload.single('file'),
  asyncHandler(async (req, res) => {
    if (!req.file) throw new AppError(400, 'file is required');
    const url = `/uploads/${req.file.filename}`;
    const type = req.file.mimetype.startsWith('video/') ? 'video' : 'image';
    res.status(201).json({ url, type });
  })
);

module.exports = router;
