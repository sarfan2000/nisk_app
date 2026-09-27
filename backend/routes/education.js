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
                        message: `A student has booked you for ${item.numberOfClasses} classes. It is pending admin payment verification.`,
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

module.exports = router;
