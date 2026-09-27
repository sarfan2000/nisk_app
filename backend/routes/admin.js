const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Booking = require('../models/Booking');
const Job = require('../models/Job');
const Product = require('../models/Product');
const ProductOrder = require('../models/ProductOrder');
const auth = require('../middleware/auth');
const role = require('../middleware/role');

// Get total overview statistics
router.get('/dashboard-stats', [auth, role(['Admin', 'Super Admin'])], async (req, res) => {
    try {
        const usersCount = await User.countDocuments();
        const activeBookings = await Booking.countDocuments({ status: 'Pending' });
        const activeJobs = await Job.countDocuments({ isActive: true });
        const pendingProducts = await Product.countDocuments({ isApproved: false });
        const totalSales = await ProductOrder.aggregate([
            { $match: { paymentStatus: 'Paid' } },
            { $group: { _id: null, totalSales: { $sum: '$total' } } }
        ]);

        res.json({
            users: usersCount,
            bookings: activeBookings,
            jobs: activeJobs,
            pendingProducts,
            revenue: totalSales.length > 0 ? totalSales[0].totalSales : 0
        });
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// User Management Actions
router.patch('/users/:id/status', [auth, role(['Admin', 'Super Admin'])], async (req, res) => {
    try {
        const { status, isVerified } = req.body;
        const user = await User.findByIdAndUpdate(req.params.id, { status, isVerified }, { new: true });
        res.json({ msg: 'User updated', user });
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// Get unverified teachers
router.get('/teachers/unverified', [auth, role(['Admin', 'Super Admin'])], async (req, res) => {
    try {
        const teachers = await User.find({ userType: 'Teacher', isVerified: false });
        res.json(teachers);
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// Get pending bookings (Paid but waiting for Admin Approval)
router.get('/bookings/pending', [auth, role(['Admin', 'Super Admin'])], async (req, res) => {
    try {
        // Find bookings where payment is Completed but status is not yet 'Admin_Approved' or beyond
        const bookings = await Booking.find({ paymentStatus: 'Completed', status: 'Pending' })
            .populate('student', 'name email phone')
            .populate('items.teacher', 'name email phone');
        res.json(bookings);
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// Admin Approve Booking (Education)
router.patch('/bookings/:id/approve', [auth, role(['Admin', 'Super Admin'])], async (req, res) => {
    try {
        const booking = await Booking.findByIdAndUpdate(req.params.id, { status: 'Admin_Approved' }, { new: true });
        res.json({ msg: 'Booking Admin Approved', booking });
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

const ManpowerBooking = require('../models/ManpowerBooking');
const Notification = require('../models/Notification');

// Get pending manpower bookings
router.get('/manpower-bookings/pending', [auth, role(['Admin', 'Super Admin'])], async (req, res) => {
    try {
        const bookings = await ManpowerBooking.find({ status: 'Pending' })
            .populate('customer', 'name email phone')
            .populate('worker', 'name email phone');
        res.json(bookings);
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// Admin Approve Manpower Booking
router.patch('/manpower-bookings/:id/approve', [auth, role(['Admin', 'Super Admin'])], async (req, res) => {
    try {
        const booking = await ManpowerBooking.findByIdAndUpdate(req.params.id, { status: 'Admin_Approved' }, { new: true });

        if (booking) {
            // Notify Worker
            const notify = new Notification({
                user: booking.worker,
                title: 'New Manpower Booking Approved',
                message: `An admin has approved the payment for your booking ${booking.orderId}. You can now accept it.`,
                type: 'Alert'
            });
            await notify.save();
        }

        res.json({ msg: 'Manpower Booking Admin Approved', booking });
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// Product Approvals
router.patch('/products/:id/approve', [auth, role(['Admin', 'Super Admin'])], async (req, res) => {
    try {
        const product = await Product.findByIdAndUpdate(req.params.id, { isApproved: true }, { new: true });
        res.json({ msg: 'Product Approved for Marketplace', product });
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

module.exports = router;
