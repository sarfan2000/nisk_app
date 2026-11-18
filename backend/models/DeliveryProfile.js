const mongoose = require('mongoose');

const DeliveryProfileSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        unique: true
    },
    nicNumber: {
        type: String,
        required: true
    },
    nicPhoto: {
        type: String,
        required: false
    },
    drivingLicenseNumber: {
        type: String,
        required: false
    },
    licensePhoto: {
        type: String,
        required: false
    },
    vehicleType: {
        type: String,
        enum: ['Motorbike', 'Three-Wheeler', 'Car/Van', 'Bicycle'],
        default: 'Motorbike'
    },
    vehicleNumber: {
        type: String,
        required: true
    },
    bankDetails: {
        bankName: { type: String, required: true },
        branch: { type: String, required: true },
        accountNumber: { type: String, required: true },
        accountHolderName: { type: String, required: true }
    },
    kycStatus: {
        type: String,
        enum: ['Pending', 'Approved', 'Rejected'],
        default: 'Pending'
    },
    rejectionReason: {
        type: String,
        default: ''
    },
    approvedAt: {
        type: Date
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('DeliveryProfile', DeliveryProfileSchema);

