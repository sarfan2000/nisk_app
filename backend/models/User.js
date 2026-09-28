const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
    name: { type: String, required: true },
    phone: { type: String, required: true, unique: true },
    email: { type: String, required: false },
    password: { type: String, required: true },
    roles: [{
        role: { type: String, enum: ['Buyer', 'Student', 'Teacher', 'Worker', 'Employer', 'Seller', 'Admin', 'Delivery'] },
        status: { type: String, enum: ['Pending', 'Active', 'Rejected', 'Suspended'], default: 'Active' },
        appliedAt: { type: Date, default: Date.now }
    }],
    userType: {
        type: String,
        required: false // Deprecated, kept temporarily for migration
    },
    location: {
        province: { type: String },
        district: { type: String },
        city: { type: String }
    },
    isVerified: { type: Boolean, default: false },
    status: { type: String, default: 'Active' },
    profilePic: { type: String, required: false },
    createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('User', UserSchema);
