const express = require('express');
const router = express.Router();
const ProductOrder = require('../models/ProductOrder');
const Notification = require('../models/Notification');
const auth = require('../middleware/auth');
const role = require('../middleware/role');

// 1. Get Unassigned Orders ready for pickup
// Only paid/confirmed orders that are "Packed" should be available to drivers
router.get('/available-orders', [auth, role(['Delivery'])], async (req, res) => {
    try {
        const orders = await ProductOrder.find({
            deliveryBoy: { $exists: false },
            orderStatus: { $in: ['Packed', 'Processing'] },
            paymentStatus: { $in: ['Paid', 'Confirmed'] }
        })
            .populate('product', 'name location')
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
            .populate('product', 'name location')
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
        const order = await ProductOrder.findOneAndUpdate(
            { orderId: req.params.orderId, deliveryBoy: { $exists: false } },
            {
                deliveryBoy: req.user.id,
                orderStatus: 'Out for Delivery'
            },
            { new: true }
        ).populate('product');

        if (!order) {
            return res.status(400).json({ msg: 'Order not found or already assigned to a rider' });
        }

        // Notify Customer
        const customerNotify = new Notification({
            user: order.customer,
            title: 'Package Out for Delivery',
            message: `A Delivery Rider has picked up your order: ${order.product.name} and is on their way!`,
            type: 'Alert'
        });
        await customerNotify.save();

        res.json({ msg: 'Order assigned to you!', order });
    } catch (err) {
        console.error(err);
        res.status(500).json({ msg: 'Server Error' });
    }
});

// 4. Mark Order as Delivered
router.patch('/complete/:orderId', [auth, role(['Delivery'])], async (req, res) => {
    try {
        const order = await ProductOrder.findOneAndUpdate(
            { orderId: req.params.orderId, deliveryBoy: req.user.id },
            { orderStatus: 'Delivered' },
            { new: true }
        ).populate('product');

        if (!order) {
            return res.status(400).json({ msg: 'Order not found or access denied' });
        }

        // Notify Customer
        const customerNotify = new Notification({
            user: order.customer,
            title: 'Package Delivered!',
            message: `Your order: ${order.product.name} has been successfully delivered.`,
            type: 'Alert'
        });
        await customerNotify.save();

        // Notify Seller
        if (order.product.seller) {
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

module.exports = router;
