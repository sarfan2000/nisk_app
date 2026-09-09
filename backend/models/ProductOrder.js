const mongoose = require('mongoose');

const ProductOrderSchema = new mongoose.Schema({
    customer: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    product: { type: mongoose.Schema.Types.ObjectId, ref: 'Product', required: true },
    quantity: { type: Number, required: true },
    deliveryLocation: { type: String, required: true },
    unitPrice: { type: Number, required: true },
    subtotal: { type: Number, required: true },
    deliveryFee: { type: Number, default: 0 },
    total: { type: Number, required: true },
    paymentStatus: { type: String, enum: ['Pending', 'Confirmed', 'Processing', 'Paid'], default: 'Pending' },
    orderStatus: {
        type: String,
        enum: ['Order Placed', 'Payment Confirmed', 'Processing', 'Packed', 'Dispatched', 'Out for Delivery', 'Delivered', 'Completed'],
        default: 'Order Placed'
    },
    createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('ProductOrder', ProductOrderSchema);
