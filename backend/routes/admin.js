const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Booking = require('../models/Booking');
const Job = require('../models/Job');
const Product = require('../models/Product');
const ProductOrder = require('../models/ProductOrder');

// Get total overview statistics
router.get('/dashboard-stats', async (req, res) => {
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
router.patch('/users/:id/status', async (req, res) => {
    try {
        const { status, isVerified } = req.body;
        const user = await User.findByIdAndUpdate(req.params.id, { status, isVerified }, { new: true });
        res.json({ msg: 'User updated', user });
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// Product Approvals
router.patch('/products/:id/approve', async (req, res) => {
    try {
        const product = await Product.findByIdAndUpdate(req.params.id, { isApproved: true }, { new: true });
        res.json({ msg: 'Product Approved for Marketplace', product });
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

module.exports = router;
