const express = require('express');
const router = express.Router();
const Notification = require('../models/Notification');

// Push general notification
router.post('/', async (req, res) => {
    try {
        const notification = new Notification(req.body);
        await notification.save();
        res.status(201).json({ msg: 'Notification triggered', notification });
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// Get User Notifications Securely
router.get('/me', require('../middleware/auth'), async (req, res) => {
    try {
        const notifications = await Notification.find({ user: req.user.id }).sort({ createdAt: -1 });
        res.json(notifications);
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// Mark all User's notifications as read
router.patch('/mark-read', require('../middleware/auth'), async (req, res) => {
    try {
        await Notification.updateMany({ user: req.user.id, read: false }, { $set: { read: true } });
        res.json({ msg: 'Notifications marked as read' });
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

module.exports = router;
