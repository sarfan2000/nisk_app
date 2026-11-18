const express = require('express');
const router = express.Router();
const ProductOrder = require('../models/ProductOrder');
const Notification = require('../models/Notification');
const auth = require('../middleware/auth');
const role = require('../middleware/role');

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
