const mongoose = require('mongoose');

const ProductSchema = new mongoose.Schema({
    seller: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    name: { type: String, required: true },
    category: { type: String, required: true },
    description: { type: String },
    images: [{ type: String }],
    price: { type: Number, required: true },
    wholesalePrice: { type: Number }, // For production module
    stock: { type: Number, required: true },
    location: { type: String },
    deliveryAvailable: { type: Boolean, default: false },
    rating: { type: Number, default: 0 },
    isApproved: { type: Boolean, default: false }, // Admin approval flag
    createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Product', ProductSchema);
