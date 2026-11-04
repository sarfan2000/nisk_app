const express = require('express');
const router = express.Router();
const Message = require('../models/Message');
const auth = require('../middleware/auth');

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
        res.status(201).json({ msg: 'Message sent successfully', message });
    } catch (err) {
        console.error('Send message error:', err);
        res.status(500).json({ msg: 'Server error' });
    }
});

// Get Messages between two users (Authenticated & Authorized)
router.get('/:userId/:contactId', auth, async (req, res) => {
    try {
        const isAdmin = req.user.userType === 'Admin' || (req.user.roles && req.user.roles.some(r => r.role === 'Admin' && r.status === 'Active'));
        if (req.user.id !== req.params.userId && req.user.id !== req.params.contactId && !isAdmin) {
            return res.status(403).json({ msg: 'Access denied: You cannot view conversations of other users' });
        }

        const messages = await Message.find({
            $or: [
                { sender: req.params.userId, receiver: req.params.contactId },
                { sender: req.params.contactId, receiver: req.params.userId }
            ]
        }).sort({ createdAt: 1 });
        res.json(messages);
    } catch (err) {
        console.error('Get messages error:', err);
        res.status(500).json({ msg: 'Server error' });
    }
});

module.exports = router;
