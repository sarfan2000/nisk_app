const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
    name: { type: String, required: true },
    phone: { type: String, required: true, unique: true },
    email: { type: String, required: false },
    password: { type: String, required: true },
    userType: {
        type: String,
        required: true,
        enum: ['Buyer', 'Student', 'Teacher', 'Worker', 'Employer', 'Seller', 'Admin']
    },
    location: {
        province: { type: String },
        district: { type: String },
        city: { type: String }
    },
    isVerified: { type: Boolean, default: false },
    status: { type: String, default: 'Active' },
    createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('User', UserSchema);
