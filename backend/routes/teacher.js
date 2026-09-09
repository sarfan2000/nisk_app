const express = require('express');
const router = express.Router();
const TeacherProfile = require('../models/TeacherProfile');
const Booking = require('../models/Booking');

// Register / Update Teacher Profile
router.post('/profile/:userId', async (req, res) => {
    try {
        const { qualifications, experience, shortDescription, availableDays, availableTime, bankInformation } = req.body;

        let profile = await TeacherProfile.findOne({ user: req.params.userId });

        if (profile) {
            // Update
            profile = await TeacherProfile.findOneAndUpdate(
                { user: req.params.userId },
                { $set: req.body },
                { new: true }
            );
        } else {
            // Create
            profile = new TeacherProfile({
                user: req.params.userId,
                qualifications,
                experience,
                shortDescription,
                availableDays,
                availableTime,
                bankInformation
            });
            await profile.save();
        }

        res.json({ msg: 'Teacher profile updated', profile });
    } catch (err) {
        console.error(err);
        res.status(500).json({ msg: 'Server error' });
    }
});

// Get Teacher Bookings
router.get('/bookings/:userId', async (req, res) => {
    try {
        // Find bookings where one of the items has this teacher
        const bookings = await Booking.find({ 'items.teacher': req.params.userId })
            .populate('student', 'name phone location')
            .populate('grade', 'name')
            .populate('items.subject', 'name');

        res.json(bookings);
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// Update Booking Status
router.patch('/booking/:bookingId/status', async (req, res) => {
    try {
        const { status } = req.body;
        const booking = await Booking.findByIdAndUpdate(req.params.bookingId, { status }, { new: true });
        res.json({ msg: 'Booking status updated', booking });
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

module.exports = router;
