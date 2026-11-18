const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Booking = require('../models/Booking');
const Job = require('../models/Job');
const Product = require('../models/Product');
const ProductOrder = require('../models/ProductOrder');
const DeliveryProfile = require('../models/DeliveryProfile');
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

// Get Pending Rider KYC Submissions
router.get('/delivery/pending-kyc', [auth, role(['Admin', 'Super Admin'])], async (req, res) => {
    try {
        const profiles = await DeliveryProfile.find({ kycStatus: 'Pending' })
            .populate('user', 'name phone email location isVerified createdAt')
            .sort({ createdAt: -1 });
        res.json(profiles);
    } catch (err) {
        console.error(err);
        res.status(500).json({ msg: 'Server error' });
    }
});

// Admin Approve or Reject Rider KYC
router.patch('/delivery/kyc-decision/:profileId', [auth, role(['Admin', 'Super Admin'])], async (req, res) => {
    try {
        const { decision, rejectionReason } = req.body; // 'Approved' or 'Rejected'

        if (!['Approved', 'Rejected'].includes(decision)) {
            return res.status(400).json({ msg: 'Invalid decision. Must be Approved or Rejected' });
        }

        const isApproved = decision === 'Approved';
        const profile = await DeliveryProfile.findById(req.params.profileId).populate('user');

        if (!profile) {
            return res.status(404).json({ msg: 'Delivery Profile not found' });
        }

        profile.kycStatus = decision;
        profile.rejectionReason = isApproved ? '' : (rejectionReason || 'Documents could not be verified');
        if (isApproved) profile.approvedAt = new Date();
        await profile.save();

        // Update the User document's isVerified flag
        if (profile.user) {
            await User.findByIdAndUpdate(profile.user._id, {
                isVerified: isApproved
            });

            // Send in-app notification to the rider
            const Notification = require('../models/Notification');
            const notif = new Notification({
                user: profile.user._id,
                title: isApproved ? 'Rider Account Verified!' : 'KYC Verification Update',
                message: isApproved
                    ? 'Congratulations! Your NISK Rider KYC has been approved. You can now accept and deliver orders!'
                    : `Your Rider KYC was not approved: ${profile.rejectionReason}. Please update your documents.`,
                type: 'Alert'
            });
            await notif.save();
        }

        res.json({ msg: `Rider KYC has been ${decision.toLowerCase()}!`, profile });
    } catch (err) {
        console.error(err);
        res.status(500).json({ msg: 'Server error: ' + err.message });
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

        if (booking && booking.items && booking.items.length > 0) {
            for (let item of booking.items) {
                if (item.teacher) {
                    const Notification = require('../models/Notification');
                    const notifyTeacher = new Notification({
                        user: item.teacher,
                        title: 'Student Payment Confirmed!',
                        message: `Student paid successfully and booked your class. Subject: ${item.subject || 'Unknown'}, Grade: ${booking.grade || 'Unknown'}, Time: ${item.schedule || 'Pending'}. Please approve.`,
                        type: 'Alert'
                    });
                    await notifyTeacher.save();
                }
            }
        }

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
