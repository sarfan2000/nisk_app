const express = require('express');
const router = express.Router();
const TeacherProfile = require('../models/TeacherProfile');
const Booking = require('../models/Booking');
const Notification = require('../models/Notification');
const upload = require('../middleware/upload');
const auth = require('../middleware/auth');
const role = require('../middleware/role');

// Get My Teacher Profile
router.get('/profile/me', [auth], async (req, res) => {
    try {
        const profile = await TeacherProfile.findOne({ user: req.user.id });
        res.json(profile || {});
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// Delete My Teacher Profile
router.delete('/profile/me', [auth], async (req, res) => {
    try {
        await TeacherProfile.findOneAndDelete({ user: req.user.id });
        res.json({ msg: 'Profile deleted successfully' });
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

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
            if (req.query.location) filter.location = new RegExp(req.query.location, 'i');
        }

        const profiles = await TeacherProfile.find(filter).populate('user', 'name phone location isVerified status profilePic');
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

// Register / Update Teacher Profile (Protected against IDOR)
router.post('/profile/:userId', [require('../middleware/auth'), upload.array('images', 1)], async (req, res) => {
    try {
        const { qualifications, experience, shortDescription, availableDays, availableTime, bankInformation, hourlyRate, subjects, grades, modes, location } = req.body;

        const isAdmin = req.user.userType === 'Admin' || (req.user.roles && req.user.roles.some(r => r.role === 'Admin' && r.status === 'Active'));
        if (req.params.userId !== 'me' && req.params.userId !== req.user.id && !isAdmin) {
            return res.status(403).json({ msg: 'Access denied: You can only update your own teacher profile' });
        }

        const userIdToUse = (req.params.userId === 'me' || !isAdmin) ? req.user.id : req.params.userId;
        let profile = await TeacherProfile.findOne({ user: userIdToUse });

        if (req.files && req.files.length > 0) {
            req.body.profilePicture = req.files[0].path;
        }

        try {
            if (subjects) req.body.subjects = typeof subjects === 'string' ? JSON.parse(subjects) : subjects;
            if (grades) req.body.grades = typeof grades === 'string' ? JSON.parse(grades) : grades;
            if (modes) req.body.modes = typeof modes === 'string' ? JSON.parse(modes) : modes;
        } catch (parseErr) {
            console.warn('JSON parse warning on profile fields:', parseErr);
        }

        if (req.body.profilePicture) {
            await require('../models/User').findByIdAndUpdate(userIdToUse, { profilePic: req.body.profilePicture }).catch(e => console.error('User profilePic sync error:', e));
        }

        if (profile) {
            profile = await TeacherProfile.findOneAndUpdate(
                { user: userIdToUse },
                { $set: req.body },
                { new: true }
            );
        } else {
            profile = new TeacherProfile({
                user: userIdToUse,
                qualifications: req.body.qualifications || [],
                experience: experience || '',
                shortDescription: shortDescription || '',
                availableDays: req.body.availableDays || [],
                availableTime: availableTime || '',
                hourlyRate: Math.max(0, parseFloat(hourlyRate) || 0),
                subjects: req.body.subjects || [],
                grades: req.body.grades || [],
                modes: req.body.modes || [],
                location: location || '',
                bankInformation: bankInformation || '',
                profilePicture: req.body.profilePicture || '',
                isApproved: true,
                isVerified: false
            });
            await profile.save();
        }

        res.json({ msg: 'Teacher profile updated', profile });
    } catch (err) {
        console.error('Teacher profile error:', err);
        res.status(500).json({ msg: 'Server error' });
    }
});

// Get Teacher Bookings
router.get('/bookings/me', [require('../middleware/auth'), require('../middleware/role')(['Teacher'])], async (req, res) => {
    try {
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
                const param = req.params.bookingId;
        const isObjectId = /^[a-f\d]{24}$/i.test(param);
        const query = isObjectId
            ? { _id: param, 'items.teacher': req.user.id }
            : { bookingId: param, 'items.teacher': req.user.id };
        const booking = await Booking.findOneAndUpdate(query, { status }, { new: true }).populate('student', 'name');

        if (booking && booking.student) {
            let message = `Your booking has been ${status} by the teacher.`;
            if (status === 'Teacher_Approved') {
                message = 'Approved by teacher, live session link started.';
            }

            const notify = new Notification({
                user: booking.student._id,
                title: 'Tutor Booking Update',
                message: message,
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
