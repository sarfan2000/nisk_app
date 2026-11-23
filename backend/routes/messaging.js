const express = require('express');
const router = express.Router();
const Message = require('../models/Message');
const User = require('../models/User');
const auth = require('../middleware/auth');

// Get My Conversations List
router.get('/conversations', auth, async (req, res) => {
    try {
        // Find all messages where user is sender or receiver
        const messages = await Message.find({
            $or: [
                { sender: req.user.id },
                { receiver: req.user.id }
            ]
        }).sort({ createdAt: -1 })
          .populate('sender', 'name profilePic')
          .populate('receiver', 'name profilePic');

        // Group by conversation partner and get latest message
        const conversationsMap = new Map();
        
        for (const msg of messages) {
            const partnerId = msg.sender._id.toString() === req.user.id 
                ? msg.receiver._id.toString() 
                : msg.sender._id.toString();
            
            if (!conversationsMap.has(partnerId)) {
                const partner = msg.sender._id.toString() === req.user.id ? msg.receiver : msg.sender;
                conversationsMap.set(partnerId, {
                    contactId: partnerId,
                    contactName: partner.name,
                    contactProfilePic: partner.profilePic,
                    lastMessage: msg.content,
                    lastMessageTime: msg.createdAt,
                    unreadCount: 0 // Can be enhanced later
                });
            }
        }

        const conversations = Array.from(conversationsMap.values());
        res.json(conversations);
    } catch (err) {
        console.error('Get conversations error:', err);
        res.status(500).json({ msg: 'Server error' });
    }
});

// Send Message (Authenticated - Sender enforced from token)
router.post('/', auth, async (req, res) => {
    try {
        const { receiver, content } = req.body;
        if (!receiver || !content || !content.trim()) {
            return res.status(400).json({ msg: 'Receiver and non-empty content are required' });
        }

        const message = new Message({
            sender: req.user.id,
            receiver,
            content: content.trim()
        });

        await message.save();
        
        // Populate sender info for response
        await message.populate('sender', 'name profilePic');
        await message.populate('receiver', 'name profilePic');
        
        res.status(201).json({ msg: 'Message sent successfully', message });
    } catch (err) {
        console.error('Send message error:', err);
        res.status(500).json({ msg: 'Server error' });
    }
});

// Get Messages with a specific contact
router.get('/chat/:contactId', auth, async (req, res) => {
    try {
        const messages = await Message.find({
            $or: [
                { sender: req.user.id, receiver: req.params.contactId },
                { sender: req.params.contactId, receiver: req.user.id }
            ]
        }).sort({ createdAt: 1 })
          .populate('sender', 'name profilePic')
          .populate('receiver', 'name profilePic');
        
        res.json(messages);
    } catch (err) {
        console.error('Get messages error:', err);
        res.status(500).json({ msg: 'Server error' });
    }
});

// Mark messages as read
router.patch('/read/:contactId', auth, async (req, res) => {
    try {
        await Message.updateMany(
            { sender: req.params.contactId, receiver: req.user.id, read: false },
            { read: true }
        );
        res.json({ msg: 'Messages marked as read' });
    } catch (err) {
        console.error('Mark read error:', err);
        res.status(500).json({ msg: 'Server error' });
    }
});

module.exports = router;
