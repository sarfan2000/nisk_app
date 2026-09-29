const express = require('express');
const router = express.Router();
const Grade = require('../models/Grade');
const Subject = require('../models/Subject');
const User = require('../models/User');
const TeacherRate = require('../models/TeacherRate');
const Booking = require('../models/Booking');
const Notification = require('../models/Notification');
const auth = require('../middleware/auth');
const role = require('../middleware/role');
const { RtcTokenBuilder, RtcRole } = require('agora-access-token');

// 1. Get all grades
router.get('/grades', async (req, res) => {
    try {
        const grades = await Grade.find({ isActive: true });
        res.json(grades);
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// 2. Get subjects assigned to a selected grade
router.get('/subjects/:gradeId', async (req, res) => {
    try {
        const subjects = await Subject.find({ grade: req.params.gradeId, isActive: true });
        res.json(subjects);
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// 3. Get teachers registered for a particular subject
router.get('/teachers/:subjectId', async (req, res) => {
    try {
        const subject = await Subject.findById(req.params.subjectId).populate({
            path: 'teachers',
            match: { isVerified: true, status: 'Active' },
            select: 'name phone location status isVerified'
        });
        if (!subject) return res.status(404).json({ msg: 'Subject not found' });
        res.json(subject.teachers);
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// 4. Get teacher's rate automatically based on subject, grade, mode
router.get('/teacher-rate', async (req, res) => {
    try {
        const { teacherId, subjectId, gradeId, mode } = req.query;
        const rate = await TeacherRate.findOne({
            teacher: teacherId,
            subject: subjectId,
            grade: gradeId,
            mode: mode
        });

        if (!rate) return res.status(404).json({ msg: 'Rate not found for this configuration' });
        res.json(rate);
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// 5. Checkout & Booking
router.post('/book', [auth, role(['Student'])], async (req, res) => {
    try {
        const { mode, gradeId, items, serviceCharge, discount } = req.body;
        const studentId = req.user.id;

        let totalSubtotal = 0;

        // Calculate subtotal
        items.forEach(item => {
            totalSubtotal += item.ratePerClass * item.numberOfClasses;
            item.subtotal = item.ratePerClass * item.numberOfClasses;
        });

        const totalBill = totalSubtotal + serviceCharge - discount;
        const bookingId = 'BK' + Date.now(); // Simple ID generation

        const booking = new Booking({
            student: studentId,
            bookingId,
            mode,
            grade: gradeId,
            items,
            totalSubtotal,
            serviceCharge,
            discount,
            totalBill
        });

        await booking.save();

        // Trigger Notification to the Teacher
        if (items && items.length > 0) {
            for (let item of items) {
                if (item.teacher) {
                    const notify = new Notification({
                        user: item.teacher,
                        title: 'New Student Booking Pending Approval',
                        message: `A student has booked you for ${item.numberOfClasses} classes. It is pending payment completion.`,
                        type: 'Alert'
                    });
                    await notify.save();
                }
            }
        }

        res.status(201).json({ msg: 'Booking successful', booking });
    } catch (err) {
        console.error(err);
        res.status(500).json({ msg: 'Server error' });
    }
});

// 6. Get My Bookings (Student)
router.get('/my-bookings', [auth, role(['Student'])], async (req, res) => {
    try {
        const studentId = req.user.id;
        // Find all bookings for this student, gracefully populate the teacher names if needed
        const bookings = await Booking.find({ student: studentId })
            .populate('items.teacher', 'name status isVerified')
            .sort({ createdAt: -1 });

        res.json(bookings);
    } catch (err) {
        console.error("GET /my-bookings error:", err);
        res.status(500).json({ msg: 'Server error' });
    }
});

// 7. Get Teacher Bookings (Teacher view)
router.get('/teacher-bookings', [auth, role(['Teacher'])], async (req, res) => {
    try {
        const teacherId = req.user.id;
        // Teacher only sees bookings that Admin has approved
        const bookings = await Booking.find({
            'items.teacher': teacherId,
            status: { $in: ['Admin_Approved', 'Teacher_Approved', 'Completed'] }
        })
            .populate('student', 'name email phone')
            .sort({ createdAt: -1 });
        res.json(bookings);
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// 8. Update Booking Status (Teacher logic)
router.patch('/bookings/:bookingId/status', [auth, role(['Teacher'])], async (req, res) => {
    try {
        const { status } = req.body;
        const booking = await Booking.findOneAndUpdate(
            { bookingId: req.params.bookingId, 'items.teacher': req.user.id },
            { status: status },
            { new: true }
        );

        if (!booking) return res.status(404).json({ msg: 'Booking not found' });

        // Notify Student
        const notify = new Notification({
            user: booking.student,
            title: 'Booking Update',
            message: `Your booking ${booking.bookingId} was ${status} by the teacher.`,
            type: 'Alert'
        });
        await notify.save();

        res.json({ msg: 'Booking status updated successfully', booking });
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// 9. Schedule Live Class (Teacher)
router.patch('/bookings/:bookingId/schedule', [auth, role(['Teacher'])], async (req, res) => {
    try {
        const { arrangedStartTime, arrangedEndTime } = req.body;

        // Generate a random meeting room ID for this class
        const meetingRoomId = 'ROOM_' + Math.random().toString(36).substring(2, 10).toUpperCase();

        const booking = await Booking.findOneAndUpdate(
            { bookingId: req.params.bookingId, 'items.teacher': req.user.id },
            { arrangedStartTime, arrangedEndTime, meetingRoomId, status: 'Teacher_Approved' },
            { new: true }
        );

        if (!booking) return res.status(404).json({ msg: 'Booking not found' });

        // Notify Student
        const notify = new Notification({
            user: booking.student,
            title: 'Live Class Scheduled!',
            message: `Your class for ${booking.bookingId} has been scheduled for ${new Date(arrangedStartTime).toLocaleString()}.`,
            type: 'Reminder'
        });
        await notify.save();

        res.json({ msg: 'Live Class Scheduled', booking });
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// 10. Get Agora RTC Token
router.get('/agora-token', auth, async (req, res) => {
    try {
        const { channelName } = req.query;
        if (!channelName) return res.status(400).json({ msg: 'channelName is required' });

        const appID = process.env.AGORA_APP_ID;
        const appCertificate = process.env.AGORA_APP_CERT;

        if (!appID || !appCertificate) {
            return res.status(500).json({ msg: 'Agora App ID or Certificate not configured in .env' });
        }

        const uid = 0; // Let Agora assign UID
        const currentTimestamp = Math.floor(Date.now() / 1000);
        const privilegeExpiredTs = currentTimestamp + 3600; // 1 hr token

        const token = RtcTokenBuilder.buildTokenWithUid(appID, appCertificate, channelName, uid, RtcRole.PUBLISHER, privilegeExpiredTs);

        res.json({ token, channelName, uid, appID });
    } catch (err) {
        console.error(err);
        res.status(500).json({ msg: 'Server error' });
    }
});

module.exports = router;
