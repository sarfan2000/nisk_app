const express = require('express');
const router = express.Router();
const Grade = require('../models/Grade');
const Subject = require('../models/Subject');
const User = require('../models/User');
const TeacherRate = require('../models/TeacherRate');
const Booking = require('../models/Booking');

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
router.post('/book', async (req, res) => {
    try {
        const { studentId, mode, gradeId, items, serviceCharge, discount } = req.body;

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
        res.status(201).json({ msg: 'Booking successful', booking });
    } catch (err) {
        console.error(err);
        res.status(500).json({ msg: 'Server error' });
    }
});

module.exports = router;
