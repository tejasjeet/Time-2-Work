const mongoose = require('mongoose');

const chatSchema = new mongoose.Schema(
  {
    jobId: { type: mongoose.Schema.Types.ObjectId, ref: 'Job', required: true },
    applicationId: { type: mongoose.Schema.Types.ObjectId, ref: 'JobApplication' },
    participants: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }],
    lastMessage: { type: String, default: '' },
    lastMessageAt: { type: Date },
  },
  { timestamps: true, collection: 'chats' }
);

chatSchema.index({ participants: 1 });
chatSchema.index({ jobId: 1, applicationId: 1 });
chatSchema.index({ lastMessageAt: -1 });

module.exports = mongoose.model('Chat', chatSchema);
