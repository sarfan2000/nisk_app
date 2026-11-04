const express = require('express');
const router = express.Router();
const Notification = require('../models/Notification');
const auth = require('../middleware/auth');
const role = require('../middleware/role');

// Push general notification (Admin only)
router.post('/', [auth, role(['Admin', 'Super Admin'])], async (req, res) => {
    try {
        const { user, title, message, type } = req.body;
        if (!user || !title || !message) {
            return res.status(400).json({ msg: 'user, title, and message are required' });
        }

        const notification = new Notification({
            user,
            title,
            message,
            type: type || 'Alert'
        });

        await notification.save();
        res.status(201).json({ msg: 'Notification triggered', notification });
    } catch (err) {
        console.error('Trigger notification error:', err);
        res.status(500).json({ msg: 'Server error' });
    }
});

// Get User Notifications Securely
router.get('/me', auth, async (req, res) => {
    try {
        const notifications = await Notification.find({ user: req.user.id }).sort({ createdAt: -1 });
        res.json(notifications);
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// Mark all User's notifications as read
router.patch('/mark-read', auth, async (req, res) => {
    try {
        await Notification.updateMany({ user: req.user.id, read: false }, { $set: { read: true } });
        res.json({ msg: 'Notifications marked as read' });
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// Delete a specific notification
router.delete('/:id', auth, async (req, res) => {
    try {
        await Notification.findOneAndDelete({ _id: req.params.id, user: req.user.id });
        res.json({ msg: 'Notification deleted' });
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

module.exports = router;
