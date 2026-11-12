const express = require('express');
const router = express.Router();
const Grade = require('../models/Grade');
const Subject = require('../models/Subject');
const User = require('../models/User');
const TeacherRate = require('../models/TeacherRate');
const TeacherProfile = require('../models/TeacherProfile');
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

// 5. Checkout & Booking (Server-side price verification)
router.post('/book', auth, async (req, res) => {
    try {
        const { mode, gradeId, items, serviceCharge, discount } = req.body;
        const studentId = req.user.id;

        if (!items || !Array.isArray(items) || items.length === 0) {
            return res.status(400).json({ msg: 'Booking items are required' });
        }

        let totalSubtotal = 0;
        const validatedItems = [];

        // Verify and calculate server-side pricing
        for (const item of items) {
            const numClasses = Math.max(1, parseInt(item.numberOfClasses) || 1);
            let rate = Math.max(0, parseFloat(item.ratePerClass) || 0);

            // âœ… FIX: Verify rate from TeacherRate (subject+grade+mode specific), 
            //         fallback to TeacherProfile hourlyRate, then client-sent rate
            if (item.teacher) {
                const specificRate = await TeacherRate.findOne({
                    teacher: item.teacher,
                    mode: mode || 'Online'
                });
                if (specificRate && specificRate.ratePerClass > 0) {
                    rate = specificRate.ratePerClass;
                } else {
                    const profile = await TeacherProfile.findOne({ user: item.teacher });
                    if (profile && profile.hourlyRate > 0) {
                        rate = profile.hourlyRate;
                    }
                }
            }

            const itemSubtotal = rate * numClasses;
            totalSubtotal += itemSubtotal;

            validatedItems.push({
                subject: item.subject || 'Tuition',
                teacher: item.teacher,
                ratePerClass: rate,
                numberOfClasses: numClasses,
                schedule: item.schedule || 'Flexible',
                subtotal: itemSubtotal
            });
        }

        const validServiceCharge = Math.max(0, parseFloat(serviceCharge) || 0);
        const validDiscount = Math.max(0, parseFloat(discount) || 0);
        const totalBill = Math.max(0, totalSubtotal + validServiceCharge - validDiscount);
        const bookingId = 'BK' + Date.now();

        const booking = new Booking({
            student: studentId,
            bookingId,
            mode: mode || 'Online',
            grade: gradeId,           // âœ… FIX: use gradeId as-is (ObjectId from client); never use 'Standard' string fallback
            items: validatedItems,
            totalSubtotal,
            serviceCharge: validServiceCharge,
            discount: validDiscount,
            totalBill
        });

        await booking.save();

        // 🔔 Send immediate booking notification to student
        const studentNotify = new Notification({
            user: studentId,
            title: 'Booking Created',
            message: `Your class booking for ${booking.bookingId} has been created. Please complete payment to confirm.`,
            type: 'Alert'
        });
        await studentNotify.save().catch(e => console.error('Student notify error:', e));

        // 🔔 Send notification to assigned teacher(s)
        for (const item of validatedItems) {
            if (item.teacher) {
                const teacherNotify = new Notification({
                    user: item.teacher,
                    title: 'New Class Booking Request',
                    message: `A student booked a class with you: ${item.subject || 'Tuition'} ().`,
                    type: 'Alert'
                });
                await teacherNotify.save().catch(e => console.error('Teacher notify error:', e));
            }
        }

        res.status(201).json({ msg: 'Booking successful', booking });
    } catch (err) {
        console.error('Education book error:', err);
        res.status(500).json({ msg: 'Server error' });
    }
});

// 6. Get My Bookings (Student)
router.get('/my-bookings', auth, async (req, res) => {
    try {
        const studentId = req.user.id;
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
// Shows Admin_Approved (waiting for teacher action) + Teacher_Approved + Completed
router.get('/teacher-bookings', [auth, role(['Teacher'])], async (req, res) => {
    try {
        const teacherId = req.user.id;
        const bookings = await Booking.find({
            'items.teacher': teacherId,
            paymentStatus: 'Completed',                                           // âœ… only paid bookings
            status: { $in: ['Admin_Approved', 'Teacher_Approved', 'Completed'] } // âœ… relevant statuses
        })
            .populate('student', 'name email phone')
            .sort({ createdAt: -1 });
        res.json(bookings);
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// 8. Update Booking Status (Teacher logic)
// âœ… FIX: Accept BOTH bookingId string (e.g. BK123) and MongoDB _id for flexibility
router.patch('/bookings/:bookingId/status', [auth, role(['Teacher'])], async (req, res) => {
    try {
        const { status } = req.body;
        const param = req.params.bookingId;

        // Determine if param is a MongoDB ObjectId or a bookingId string
        const isObjectId = /^[a-f\d]{24}$/i.test(param);
        const query = isObjectId
            ? { _id: param, 'items.teacher': req.user.id }
            : { bookingId: param, 'items.teacher': req.user.id };

        const booking = await Booking.findOneAndUpdate(
            query,
            { status: status },
            { new: true }
        );

        if (!booking) return res.status(404).json({ msg: 'Booking not found' });

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

        if (!arrangedStartTime) {
            return res.status(400).json({ msg: 'arrangedStartTime is required' });
        }

        const meetingRoomId = 'ROOM_' + Math.random().toString(36).substring(2, 10).toUpperCase();

        // âœ… FIX: Accept both _id and bookingId; also set status to Teacher_Approved when scheduling
        const param = req.params.bookingId;
        const isObjectId = /^[a-f\d]{24}$/i.test(param);
        const query = isObjectId
            ? { _id: param, 'items.teacher': req.user.id }
            : { bookingId: param, 'items.teacher': req.user.id };

        const booking = await Booking.findOneAndUpdate(
            query,
            { arrangedStartTime, arrangedEndTime, meetingRoomId, status: 'Teacher_Approved' },
            { new: true }
        );

        if (!booking) return res.status(404).json({ msg: 'Booking not found' });

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

// 10. Get Agora RTC Token (Protected & Authorized)
router.get('/agora-token', auth, async (req, res) => {
    try {
        const { channelName } = req.query;
        if (!channelName) return res.status(400).json({ msg: 'channelName is required' });

        // Authorization check: Verify user is a student, teacher, or admin for this class
        const booking = await Booking.findOne({
            $or: [
                { meetingRoomId: channelName },
                { bookingId: channelName }
            ]
        });

        const isAdmin = req.user.userType === 'Admin' || (req.user.roles && req.user.roles.some(r => r.role === 'Admin' && r.status === 'Active'));

        if (booking && !isAdmin) {
            const isStudent = booking.student.toString() === req.user.id;
            const isTeacher = booking.items.some(i => i.teacher && i.teacher.toString() === req.user.id);
            if (!isStudent && !isTeacher) {
                return res.status(403).json({ msg: 'Access denied: You are not authorized for this live class' });
            }
        }

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
        console.error('Agora token generation error:', err);
        res.status(500).json({ msg: 'Server error' });
    }
});

module.exports = router;
