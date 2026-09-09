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

// Get User Notifications
router.get('/:userId', async (req, res) => {
    try {
        const notifications = await Notification.find({ user: req.params.userId }).sort({ createdAt: -1 });
        res.json(notifications);
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

module.exports = router;
