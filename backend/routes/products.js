const express = require('express');
const router = express.Router();
const Product = require('../models/Product');
const ProductOrder = require('../models/ProductOrder');
const upload = require('../middleware/upload');
const auth = require('../middleware/auth');
const role = require('../middleware/role');

// 1. Create Product (Seller / Production Provider)
router.post('/', [auth, role(['Seller']), upload.array('images', 5)], async (req, res) => {
    try {
        const productData = req.body;

        // Map Cloudinary secure URLs securely if files exist
        if (req.files && req.files.length > 0) {
            productData.images = req.files.map(file => file.path);
        }

        const product = new Product({
            ...productData,
            seller: req.user.id // Enforced by auth
        });

        await product.save();
        res.status(201).json({ msg: 'Product listed successfully', product });
    } catch (err) {
        console.error("POST /products error:", err);
        res.status(500).json({ msg: 'Server error', error: err.message });
    }
});

// Admin Review / Verify Product
router.patch('/verify/:productId', [auth, role(['Admin', 'Super Admin'])], async (req, res) => {
    try {
        const { isApproved } = req.body;
        const product = await Product.findByIdAndUpdate(
            req.params.productId,
            { isApproved },
            { new: true }
        );
        res.json({ msg: 'Product verification status updated', product });
    } catch (err) {
        console.error(err);
        res.status(500).json({ msg: 'Server error' });
    }
});

// 2. Browse Products (Customer)
router.get('/', async (req, res) => {
    try {
        const products = await Product.find({ stock: { $gt: 0 } }).populate('seller', 'name location');
        res.json(products);
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// 3. Purchase / Create Order (Customer)
router.post('/order', [auth, role(['Buyer', 'Student', 'Employer'])], async (req, res) => {
    try {
        const { productId, quantity, deliveryLocation, deliveryFee } = req.body;
        const customerId = req.user.id;

        const product = await Product.findById(productId);
        if (!product || product.stock < quantity) {
            return res.status(400).json({ msg: 'Product unavailable or insufficient stock' });
        }

        const subtotal = product.price * quantity;
        const total = subtotal + deliveryFee;
        const orderId = 'PR' + Date.now() + Math.random().toString().slice(2, 6);

        const order = new ProductOrder({
            orderId,
            customer: customerId,
            product: productId,
            quantity,
            deliveryLocation,
            unitPrice: product.price,
            subtotal,
            deliveryFee,
            total
        });

        await order.save();

        res.status(201).json({ msg: 'Order placed successfully', order, paymentUrl: `/api/payment/checkout/${orderId}` });
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// 4. Get My Orders (Customer)
router.get('/my-orders', [auth, role(['Buyer', 'Student', 'Employer'])], async (req, res) => {
    try {
        const orders = await ProductOrder.find({ customer: req.user.id })
            .populate('product')
            .sort({ createdAt: -1 });
        res.json(orders);
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// 5. Get Seller Orders (Seller)
router.get('/seller-orders', [auth, role(['Seller'])], async (req, res) => {
    try {
        const myProducts = await Product.find({ seller: req.user.id }).select('_id');
        const productIds = myProducts.map(p => p._id);

        const orders = await ProductOrder.find({ product: { $in: productIds } })
            .populate('product')
            .populate('customer', 'name phone')
            .sort({ createdAt: -1 });
        res.json(orders);
    } catch (err) {
        console.error(err);
        res.status(500).json({ msg: 'Server error' });
    }
});

// 6. Update Order Status (Seller Approval)
router.patch('/orders/:orderId/status', [auth, role(['Seller'])], async (req, res) => {
    try {
        const { orderStatus } = req.body;
        const myProducts = await Product.find({ seller: req.user.id }).select('_id');
        const productIds = myProducts.map(p => p._id);

        const order = await ProductOrder.findOneAndUpdate(
            { orderId: req.params.orderId, product: { $in: productIds } },
            { orderStatus },
            { new: true }
        ).populate('product');

        if (order) {
            const Notification = require('../models/Notification');
            const notify = new Notification({
                user: order.customer,
                title: 'Order Tracking Update',
                message: `Your product '${order.product.name}' is now marked as: ${orderStatus}.`,
                type: 'Alert'
            });
            await notify.save();

            if (orderStatus === 'Packed') {
                const User = require('../models/User');
                // Fix: 'roles' is an array of objects, must query 'roles.role'
                const deliveryBoys = await User.find({ 'roles.role': 'Delivery' });

                if (deliveryBoys.length > 0) {
                    const deliveryNotifs = deliveryBoys.map(boy => ({
                        user: boy._id,
                        title: 'New Delivery Available!',
                        message: `A new package ('${order.product.name}') is packed and ready for pickup!`,
                        type: 'Alert'
                    }));
                    await Notification.insertMany(deliveryNotifs);
                }
            }
        }

        res.json(order);
    } catch (err) {
        console.error(err);
        res.status(500).json({ msg: 'Server error' });
    }
});

module.exports = router;
