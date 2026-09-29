const express = require('express');
const router = express.Router();
const TeacherProfile = require('../models/TeacherProfile');
const Booking = require('../models/Booking');
const Notification = require('../models/Notification');
const upload = require('../middleware/upload');

// Get All Teacher Profiles (Find Tutor) - Only shows verified teachers!
// Accepts ?subject=Science&grade=Grade 5
router.get('/', async (req, res) => {
    try {
        let filter = { isVerified: true };

        if (req.query.search) {
            const regex = new RegExp(req.query.search, 'i');
            const User = require('../models/User');
            const matchingUsers = await User.find({ name: regex, 'roles.role': 'Teacher' }).select('_id');
            const userIds = matchingUsers.map(u => u._id);

            filter.$or = [
                { subjects: { $elemMatch: { $regex: regex } } },
                { modes: { $elemMatch: { $regex: regex } } },
                { grades: { $elemMatch: { $regex: regex } } },
                { location: regex },
                { user: { $in: userIds } }
            ];
        } else {
            if (req.query.subject) filter.subjects = { $in: [req.query.subject] };
            if (req.query.grade) filter.grades = { $in: [req.query.grade] };
            if (req.query.mode) filter.modes = { $in: [req.query.mode] };
            if (req.query.location) filter.location = new RegExp(req.query.location, 'i'); // case-insensitive match
        }

        const profiles = await TeacherProfile.find(filter).populate('user', 'name phone location isVerified status');
        res.json(profiles);
    } catch (err) {
        console.error(err);
        res.status(500).json({ msg: 'Server error' });
    }
});

// Get Unique Filters for Find Tutor Dropdowns
router.get('/filters', async (req, res) => {
    try {
        let match = { isVerified: true };
        if (req.query.mode) match.modes = { $in: [req.query.mode] };
        if (req.query.location) match.location = new RegExp(req.query.location, 'i');
        if (req.query.grade) match.grades = { $in: [req.query.grade] };

        const profiles = await TeacherProfile.find(match).populate('user', 'location');

        const locations = new Set();
        const grades = new Set();
        const subjects = new Set();

        profiles.forEach(p => {
            if (p.location) locations.add(p.location);
            else if (p.user && p.user.location) locations.add(p.user.location);

            if (p.grades) p.grades.forEach(g => grades.add(g));
            if (p.subjects) p.subjects.forEach(s => subjects.add(s));
        });

        res.json({
            locations: Array.from(locations),
            grades: Array.from(grades),
            subjects: Array.from(subjects)
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ msg: 'Server error' });
    }
});

// Admin Review / Verify Teacher (Hybrid Model)
router.patch('/verify/:profileId', [require('../middleware/auth'), require('../middleware/role')(['Admin', 'Super Admin'])], async (req, res) => {
    try {
        const { isVerified } = req.body;
        const profile = await TeacherProfile.findByIdAndUpdate(
            req.params.profileId,
            { isVerified },
            { new: true }
        );
        if (profile && profile.user && isVerified) {
            await require('../models/User').findByIdAndUpdate(profile.user, { isVerified: true, status: 'Active' });
        } else if (profile && profile.user && !isVerified) {
            await require('../models/User').findByIdAndUpdate(profile.user, { isVerified: false });
        }
        res.json({ msg: 'Profile verification status updated', profile });
    } catch (err) {
        console.error(err);
        res.status(500).json({ msg: 'Server error' });
    }
});

// Register / Update Teacher Profile
router.post('/profile/:userId', [require('../middleware/auth'), upload.array('images', 1)], async (req, res) => {
    try {
        const { qualifications, experience, shortDescription, availableDays, availableTime, bankInformation, hourlyRate, subjects, grades, modes, location } = req.body;

        const userIdToUse = req.params.userId === 'me' ? req.user.id : req.params.userId;
        let profile = await TeacherProfile.findOne({ user: userIdToUse });

        if (req.files && req.files.length > 0) {
            req.body.profilePicture = req.files[0].path;
        }

        if (subjects) req.body.subjects = JSON.parse(subjects);
        if (grades) req.body.grades = JSON.parse(grades);
        if (modes) req.body.modes = JSON.parse(modes);

        if (profile) {
            // Update
            profile = await TeacherProfile.findOneAndUpdate(
                { user: userIdToUse },
                { $set: req.body },
                { new: true }
            );
        } else {
            profile = new TeacherProfile({
                user: userIdToUse,
                qualifications,
                experience,
                shortDescription,
                availableDays,
                availableTime,
                hourlyRate,
                subjects: req.body.subjects || [],
                grades: req.body.grades || [],
                modes: req.body.modes || [],
                location: location || '',
                bankInformation,
                profilePicture: req.body.profilePicture || '',
                isApproved: true, // Hybrid Model: Show immediately
                isVerified: false // Needs Admin Badge
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
router.get('/bookings/me', [require('../middleware/auth'), require('../middleware/role')(['Teacher'])], async (req, res) => {
    try {
        // Find bookings where admin has approved
        const bookings = await Booking.find({
            'items.teacher': req.user.id,
            status: { $in: ['Admin_Approved', 'Teacher_Approved', 'Completed'] }
        })
            .populate('student', 'name phone location')
            .populate('grade', 'name')
            .populate('items.subject', 'name');

        res.json(bookings);
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// Update Booking Status
router.patch('/booking/:bookingId/status', [require('../middleware/auth'), require('../middleware/role')(['Teacher'])], async (req, res) => {
    try {
        const { status } = req.body;
        const booking = await Booking.findOneAndUpdate({ _id: req.params.bookingId, 'items.teacher': req.user.id }, { status }, { new: true }).populate('student', 'name');

        if (booking && booking.student) {
            const notify = new Notification({
                user: booking.student._id,
                title: 'Tutor Booking Update',
                message: `Your booking for ${booking.items[0]?.subject || 'a class'} has been ${status} by the teacher.`,
                type: 'Alert'
            });
            await notify.save();
        }

        res.json({ msg: 'Booking status updated', booking });
    } catch (err) {
        console.error(err);
        res.status(500).json({ msg: 'Server error' });
    }
});

module.exports = router;
