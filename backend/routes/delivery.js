const express = require('express');
const router = express.Router();
const ProductOrder = require('../models/ProductOrder');
const Notification = require('../models/Notification');
const DeliveryProfile = require('../models/DeliveryProfile');
const User = require('../models/User');
const upload = require('../middleware/upload');
const auth = require('../middleware/auth');
const role = require('../middleware/role');

// 0. Get My Delivery Profile & KYC Status
router.get('/profile/me', [auth, role(['Delivery'])], async (req, res) => {
    try {
        const user = await User.findById(req.user.id).select('name phone email location isVerified profilePic');
        const profile = await DeliveryProfile.findOne({ user: req.user.id });
        res.json({ user, profile });
    } catch (err) {
        console.error(err);
        res.status(500).json({ msg: 'Server Error' });
    }
});

// 0b. Submit / Update Rider KYC Documents & Details
router.post('/profile/kyc', [auth, role(['Delivery']), upload.array('images', 2)], async (req, res) => {
    try {
        const {
            nicNumber,
            drivingLicenseNumber,
            vehicleType,
            vehicleNumber,
            bankName,
            branch,
            accountNumber,
            accountHolderName
        } = req.body;

        if (!nicNumber || !vehicleNumber || !bankName || !accountNumber || !accountHolderName) {
            return res.status(400).json({ msg: 'Please provide all required fields: NIC, Vehicle Number, and Bank Account Details' });
        }

        let nicPhoto = '';
        let licensePhoto = '';

        if (req.files && req.files.length > 0) {
            nicPhoto = req.files[0].path;
            if (req.files.length > 1) {
                licensePhoto = req.files[1].path;
            }
        }

        const profileData = {
            user: req.user.id,
            nicNumber: nicNumber.trim(),
            drivingLicenseNumber: (drivingLicenseNumber || '').trim(),
            vehicleType: vehicleType || 'Motorbike',
            vehicleNumber: vehicleNumber.trim().toUpperCase(),
            bankDetails: {
                bankName: bankName.trim(),
                branch: (branch || 'Main Branch').trim(),
                accountNumber: accountNumber.trim(),
                accountHolderName: accountHolderName.trim()
            },
            kycStatus: 'Pending',
            rejectionReason: ''
        };

        if (nicPhoto) profileData.nicPhoto = nicPhoto;
        if (licensePhoto) profileData.licensePhoto = licensePhoto;

        const profile = await DeliveryProfile.findOneAndUpdate(
            { user: req.user.id },
            { $set: profileData },
            { new: true, upsert: true }
        );

        // Notify Admin of new KYC submission
        const admins = await User.find({ userType: 'Admin' });
        if (admins.length > 0) {
            const adminNotifs = admins.map(admin => ({
                user: admin._id,
                title: 'New Rider KYC Submitted',
                message: `Delivery rider '${req.user.name || 'User'}' (${vehicleType} - ${vehicleNumber}) submitted KYC documents for approval.`,
                type: 'Alert'
            }));
            await Notification.insertMany(adminNotifs);
        }

        res.json({ msg: 'KYC documents submitted successfully! Admin will review and verify your account.', profile });
    } catch (err) {
        console.error('KYC submission error:', err);
        res.status(500).json({ msg: 'Server Error: ' + err.message });
    }
});

// 1. Get Unassigned Orders ready for pickup
// Only paid/confirmed orders that are ready should be available to drivers
router.get('/available-orders', [auth, role(['Delivery'])], async (req, res) => {
    try {
        const orders = await ProductOrder.find({
            $or: [
                { deliveryBoy: { $exists: false } },
                { deliveryBoy: null }
            ],
            orderStatus: { $in: ['Packed', 'Processing', 'Payment Confirmed', 'Dispatched'] },
            paymentStatus: { $in: ['Paid', 'Confirmed'] }
        })
            .populate({
                path: 'product',
                select: 'name price location images seller',
                populate: { path: 'seller', select: 'name phone location' }
            })
            .populate('customer', 'name phone location')
            .sort({ createdAt: -1 });

        res.json(orders);
    } catch (err) {
        console.error(err);
        res.status(500).json({ msg: 'Server Error' });
    }
});

// 2. Get Deliveries accepted by this Delivery Boy
router.get('/my-deliveries', [auth, role(['Delivery'])], async (req, res) => {
    try {
        const orders = await ProductOrder.find({
            deliveryBoy: req.user.id
        })
            .populate({
                path: 'product',
                select: 'name price location images seller',
                populate: { path: 'seller', select: 'name phone location' }
            })
            .populate('customer', 'name phone location')
            .sort({ createdAt: -1 });

        res.json(orders);
    } catch (err) {
        console.error(err);
        res.status(500).json({ msg: 'Server Error' });
    }
});

// 3. Accept an Order for Delivery
router.patch('/accept/:orderId', [auth, role(['Delivery'])], async (req, res) => {
    try {
        // Enforce: Rider MUST be verified by Admin before accepting delivery jobs
        const user = await User.findById(req.user.id);
        if (!user || !user.isVerified) {
            return res.status(403).json({
                msg: 'Account verification required! Please submit your KYC documents and wait for Admin approval before accepting delivery orders.'
            });
        }

        const order = await ProductOrder.findOne({
            orderId: req.params.orderId,
            $or: [
                { deliveryBoy: { $exists: false } },
                { deliveryBoy: null }
            ]
        }).populate('product');

        if (!order) {
            return res.status(400).json({ msg: 'Order not found or already assigned to another rider' });
        }

        // Generate OTP if not present
        if (!order.deliveryOtp) {
            order.deliveryOtp = Math.floor(1000 + Math.random() * 9000).toString();
        }

        order.deliveryBoy = req.user.id;
        order.orderStatus = 'Out for Delivery';
        await order.save();

        // Notify Customer with Delivery OTP
        const customerNotify = new Notification({
            user: order.customer,
            title: 'Package Out for Delivery!',
            message: `A rider has picked up your order for '${order.product.name}'. Your Security OTP is ${order.deliveryOtp}. Please provide this to the rider upon delivery.`,
            type: 'Alert'
        });
        await customerNotify.save();

        res.json({ msg: 'Order assigned to you!', order });
    } catch (err) {
        console.error(err);
        res.status(500).json({ msg: 'Server Error' });
    }
});

// 4. Mark Order as Delivered (with OTP Verification)
router.post('/verify-complete/:orderId', [auth, role(['Delivery'])], async (req, res) => {
    try {
        const { otp } = req.body;
        const order = await ProductOrder.findOne({
            orderId: req.params.orderId,
            deliveryBoy: req.user.id
        }).populate('product');

        if (!order) {
            return res.status(404).json({ msg: 'Order not found or not assigned to you' });
        }

        if (order.orderStatus === 'Delivered') {
            return res.status(400).json({ msg: 'This order is already marked as Delivered' });
        }

        // Verify OTP if order has one
        if (order.deliveryOtp) {
            if (!otp) {
                return res.status(400).json({ msg: 'Please enter the 4-digit Customer Delivery OTP' });
            }
            if (order.deliveryOtp.trim() !== otp.toString().trim()) {
                return res.status(400).json({ msg: 'Invalid Delivery OTP. Please verify with the customer.' });
            }
        }

        order.orderStatus = 'Delivered';
        order.deliveredAt = new Date();
        await order.save();

        // Notify Customer
        const customerNotify = new Notification({
            user: order.customer,
            title: 'Package Delivered Successfully!',
            message: `Your order for '${order.product.name}' has been delivered. Thank you for using NISK!`,
            type: 'Alert'
        });
        await customerNotify.save();

        // Notify Seller
        if (order.product && order.product.seller) {
            const sellerNotify = new Notification({
                user: order.product.seller,
                title: 'Product Delivered to Buyer!',
                message: `Your item '${order.product.name}' (Order ${order.orderId}) was delivered successfully by the rider.`,
                type: 'Alert'
            });
            await sellerNotify.save();
        }

        res.json({
            msg: 'Delivery completed successfully!',
            earnedFee: order.deliveryFee || 300,
            order
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ msg: 'Server Error' });
    }
});

// Legacy completion fallback for backwards compatibility
router.patch('/complete/:orderId', [auth, role(['Delivery'])], async (req, res) => {
    try {
        const order = await ProductOrder.findOneAndUpdate(
            { orderId: req.params.orderId, deliveryBoy: req.user.id },
            { orderStatus: 'Delivered', deliveredAt: new Date() },
            { new: true }
        ).populate('product');

        if (!order) {
            return res.status(400).json({ msg: 'Order not found or access denied' });
        }

        const customerNotify = new Notification({
            user: order.customer,
            title: 'Package Delivered!',
            message: `Your order: ${order.product.name} has been successfully delivered.`,
            type: 'Alert'
        });
        await customerNotify.save();

        if (order.product && order.product.seller) {
            const sellerNotify = new Notification({
                user: order.product.seller,
                title: 'Order Delivered Successfully!',
                message: `Great news! Your product '${order.product.name}' was successfully delivered to the buyer.`,
                type: 'Alert'
            });
            await sellerNotify.save();
        }

        res.json({ msg: 'Delivery completed!', order });
    } catch (err) {
        console.error(err);
        res.status(500).json({ msg: 'Server Error' });
    }
});

// 5. Rider Earnings and Performance Summary
router.get('/earnings', [auth, role(['Delivery'])], async (req, res) => {
    try {
        const deliveredOrders = await ProductOrder.find({
            deliveryBoy: req.user.id,
            orderStatus: 'Delivered'
        })
            .populate('product', 'name price')
            .populate('customer', 'name location')
            .sort({ deliveredAt: -1, createdAt: -1 });

        const startOfToday = new Date();
        startOfToday.setHours(0, 0, 0, 0);

        let totalEarnings = 0;
        let todayEarnings = 0;
        let todayCount = 0;

        deliveredOrders.forEach(o => {
            const fee = Number(o.deliveryFee) || 300;
            totalEarnings += fee;
            const completionTime = o.deliveredAt ? new Date(o.deliveredAt) : new Date(o.createdAt);
            if (completionTime >= startOfToday) {
                todayEarnings += fee;
                todayCount += 1;
            }
        });

        const activeDeliveriesCount = await ProductOrder.countDocuments({
            deliveryBoy: req.user.id,
            orderStatus: 'Out for Delivery'
        });

        res.json({
            totalDeliveries: deliveredOrders.length,
            totalEarnings,
            todayDeliveries: todayCount,
            todayEarnings,
            activeDeliveries: activeDeliveriesCount,
            ratePerDelivery: 300,
            recentDeliveries: deliveredOrders.slice(0, 25)
        });
    } catch (err) {
        console.error('Earnings error:', err);
        res.status(500).json({ msg: 'Server Error' });
    }
});

module.exports = router;
