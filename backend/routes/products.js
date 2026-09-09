const express = require('express');
const router = express.Router();
const Product = require('../models/Product');
const ProductOrder = require('../models/ProductOrder');
const upload = require('../middleware/upload');
const auth = require('../middleware/auth');

// 1. Create Product (Seller / Production Provider)
router.post('/', [auth, upload.array('images', 5)], async (req, res) => {
    try {
        const productData = req.body;

        // Map Cloudinary secure URLs securely if files exist
        if (req.files && req.files.length > 0) {
            productData.images = req.files.map(file => file.path);
        }

        const product = new Product({
            ...productData,
            seller: req.user.id, // Enforced by auth
            isApproved: false
        });

        await product.save();
        res.status(201).json({ msg: 'Product listed successfully pending approval', product });
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// 2. Browse Products (Customer)
router.get('/', async (req, res) => {
    try {
        const products = await Product.find({ isApproved: true, stock: { $gt: 0 } }).populate('seller', 'name location');
        res.json(products);
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// 3. Purchase / Create Order (Customer)
router.post('/order', async (req, res) => {
    try {
        const { customerId, productId, quantity, deliveryLocation, deliveryFee } = req.body;

        const product = await Product.findById(productId);
        if (!product || product.stock < quantity) {
            return res.status(400).json({ msg: 'Product unavailable or insufficient stock' });
        }

        const subtotal = product.price * quantity;
        const total = subtotal + deliveryFee;

        const order = new ProductOrder({
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

        // Deduct Stock
        product.stock -= quantity;
        await product.save();

        res.status(201).json({ msg: 'Order placed successfully', order });
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// 4. Get My Orders (Customer)
router.get('/orders/:customerId', async (req, res) => {
    try {
        const orders = await ProductOrder.find({ customer: req.params.customerId }).populate('product');
        res.json(orders);
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

module.exports = router;
