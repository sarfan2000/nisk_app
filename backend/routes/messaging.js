const express = require('express');
const router = express.Router();
const Message = require('../models/Message');

// Send Message
router.post('/', async (req, res) => {
    try {
        const message = new Message(req.body);
        await message.save();
        res.status(201).json({ msg: 'Message sent successfully', message });
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// Get Messages between two users
router.get('/:userId/:contactId', async (req, res) => {
    try {
        const messages = await Message.find({
            $or: [
                { sender: req.params.userId, receiver: req.params.contactId },
                { sender: req.params.contactId, receiver: req.params.userId }
            ]
        }).sort({ createdAt: 1 });
        res.json(messages);
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

module.exports = router;
