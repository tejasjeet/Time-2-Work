const express = require('express');
const { z } = require('zod');
const { Chat, Message, User } = require('../models');
const { requireAuth } = require('../middleware/auth');
const { validateBody } = require('../middleware/validate');
const { AppError, asyncHandler } = require('../utils/errors');
const { chatDto, messageDto } = require('../utils/serializers');
const { parsePagination, paginated } = require('../utils/pagination');
const { emitToChat } = require('../sockets');
const { notifyUser } = require('../utils/notify');

const router = express.Router();

async function loadChatForUser(chatId, userId, isAdmin) {
  const chat = await Chat.findById(chatId).populate(
    'participants',
    'name photoUrl role avgRating ratingCount verified status'
  );
  if (!chat) throw new AppError(404, 'Chat not found');
  const isParticipant = chat.participants.some((p) => String(p._id || p) === String(userId));
  if (!isParticipant && !isAdmin) throw new AppError(403, 'Not a participant');
  return chat;
}

router.get(
  '/',
  requireAuth,
  asyncHandler(async (req, res) => {
    const { page, limit, skip } = parsePagination(req.query);
    const filter = req.user.role === 'admin' ? {} : { participants: req.user.id };
    const [items, total] = await Promise.all([
      Chat.find(filter)
        .sort({ lastMessageAt: -1, createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .populate('participants', 'name photoUrl role avgRating ratingCount verified status'),
      Chat.countDocuments(filter),
    ]);
    res.json(paginated(items.map(chatDto), { page, limit, total }));
  })
);

router.get(
  '/:id/messages',
  requireAuth,
  asyncHandler(async (req, res) => {
    await loadChatForUser(req.params.id, req.user.id, req.user.role === 'admin');
    const { page, limit, skip } = parsePagination(req.query);
    const filter = { chatId: req.params.id };
    const [items, total] = await Promise.all([
      Message.find(filter)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .populate('senderId', 'name photoUrl role avgRating ratingCount verified status'),
      Message.countDocuments(filter),
    ]);
    res.json(
      paginated(
        items.map((m) => messageDto({ ...m.toObject(), sender: m.senderId })).reverse(),
        { page, limit, total }
      )
    );
  })
);

router.post(
  '/:id/messages',
  requireAuth,
  validateBody(z.object({
    text: z.string().optional(),
    imageUrl: z.string().optional(),
    videoUrl: z.string().optional(),
  })),
  asyncHandler(async (req, res) => {
    const { text, imageUrl, videoUrl } = req.body;
    if (!text && !imageUrl && !videoUrl) throw new AppError(400, 'text, imageUrl, or videoUrl required');
    const chat = await loadChatForUser(req.params.id, req.user.id, req.user.role === 'admin');

    const participantIds = chat.participants.map((p) => String(p._id || p));
    const users = await User.find({ _id: { $in: participantIds } }).select('blockedUsers');
    const blocked = users.some((u) =>
      (u.blockedUsers || []).some((b) => participantIds.includes(String(b)))
    );
    if (blocked) throw new AppError(403, 'Chat is blocked');

    const msg = await Message.create({
      chatId: chat._id,
      senderId: req.user.id,
      text: text || '',
      imageUrl: imageUrl || '',
      videoUrl: videoUrl || '',
    });
    chat.lastMessage = text || (videoUrl ? '[video]' : imageUrl ? '[image]' : '');
    chat.lastMessageAt = new Date();
    await chat.save();
    const populated = await msg.populate('senderId', 'name photoUrl role avgRating ratingCount verified status');
    const dto = messageDto({ ...populated.toObject(), sender: populated.senderId });
    emitToChat(String(chat._id), 'message', dto);

    const others = participantIds.filter((id) => id !== req.user.id);
    await Promise.all(
      others.map((id) =>
        notifyUser(id, {
          title: 'New message',
          body: text || (videoUrl ? 'Sent a video' : 'Sent an image'),
          type: 'chat',
          data: { chatId: String(chat._id) },
        })
      )
    );
    res.status(201).json({ message: dto });
  })
);

module.exports = router;
