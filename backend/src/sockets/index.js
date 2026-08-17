const { Server } = require('socket.io');
const { verifyAccessToken } = require('../utils/jwt');
const { User, Chat, Message } = require('../models');
const { messageDto, publicUser } = require('../utils/serializers');

let io = null;

function getIO() {
  return io;
}

function initSockets(httpServer) {
  io = new Server(httpServer, {
    cors: { origin: true, credentials: true },
  });

  io.use(async (socket, next) => {
    try {
      const token =
        socket.handshake.auth?.token ||
        socket.handshake.query?.token ||
        (socket.handshake.headers.authorization || '').replace(/^Bearer\s+/i, '');
      if (!token) return next(new Error('Unauthorized'));
      const payload = verifyAccessToken(token);
      if (payload.kind === 'admin') {
        socket.user = { id: payload.sub, role: 'admin', kind: 'admin' };
        return next();
      }
      const user = await User.findById(payload.sub);
      if (!user || user.status !== 'active') return next(new Error('Unauthorized'));
      socket.user = { id: String(user._id), role: user.role, kind: 'user', name: user.name };
      next();
    } catch {
      next(new Error('Unauthorized'));
    }
  });

  io.on('connection', (socket) => {
    socket.join(`user:${socket.user.id}`);
    socket.emit('status', { userId: socket.user.id, status: 'online' });

    socket.on('join', async ({ chatId } = {}) => {
      if (!chatId) return;
      const chat = await Chat.findById(chatId);
      if (!chat) return;
      const isParticipant = chat.participants.some((p) => String(p) === socket.user.id);
      if (!isParticipant && socket.user.role !== 'admin') return;
      socket.join(`chat:${chatId}`);
    });

    socket.on('message', async (payload = {}) => {
      try {
        const { chatId, text, imageUrl } = payload;
        if (!chatId || (!text && !imageUrl)) return;
        const chat = await Chat.findById(chatId);
        if (!chat) return;
        if (!chat.participants.some((p) => String(p) === socket.user.id)) return;
        const blocked = await isBlockedBetween(socket.user.id, chat.participants);
        if (blocked) return;
        const msg = await Message.create({
          chatId,
          senderId: socket.user.id,
          text: text || '',
          imageUrl: imageUrl || '',
        });
        chat.lastMessage = text || (imageUrl ? '[image]' : '');
        chat.lastMessageAt = new Date();
        await chat.save();
        const populated = await msg.populate('senderId', 'name photoUrl role avgRating ratingCount verified status');
        const dto = messageDto({ ...populated.toObject(), sender: populated.senderId });
        io.to(`chat:${chatId}`).emit('message', dto);
      } catch (err) {
        socket.emit('error', { message: err.message });
      }
    });

    socket.on('typing', ({ chatId, isTyping } = {}) => {
      if (!chatId) return;
      socket.to(`chat:${chatId}`).emit('typing', {
        chatId,
        userId: socket.user.id,
        isTyping: Boolean(isTyping),
      });
    });

    socket.on('status', ({ status } = {}) => {
      const value = status || 'online';
      socket.broadcast.emit('status', { userId: socket.user.id, status: value });
    });

    socket.on('disconnect', () => {
      socket.broadcast.emit('status', { userId: socket.user.id, status: 'offline' });
    });
  });

  return io;
}

async function isBlockedBetween(userId, participantIds) {
  const users = await User.find({ _id: { $in: participantIds } }).select('blockedUsers');
  return users.some((u) =>
    (u.blockedUsers || []).some((b) => participantIds.map(String).includes(String(b)))
  );
}

function emitToUser(userId, event, payload) {
  if (!io) return;
  io.to(`user:${userId}`).emit(event, payload);
}

function emitToChat(chatId, event, payload) {
  if (!io) return;
  io.to(`chat:${chatId}`).emit(event, payload);
}

module.exports = { initSockets, getIO, emitToUser, emitToChat, publicUser };
