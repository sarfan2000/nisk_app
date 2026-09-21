const mongoose = require('mongoose');

const ManpowerBookingSchema = new mongoose.Schema({
    orderId: { type: String, required: true, unique: true },
    customer: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    worker: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    jobCategory: { type: String, required: true },
    duration: { type: Number, required: true }, // e.g. hours or days
    rate: { type: Number, required: true },
    subtotal: { type: Number, required: true },
    serviceCharge: { type: Number, default: 0 },
    total: { type: Number, required: true },
    paymentStatus: { type: String, enum: ['Pending', 'Completed', 'Failed'], default: 'Pending' },
    status: { type: String, enum: ['Pending', 'Accepted', 'Rejected', 'Completed'], default: 'Pending' },
    createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('ManpowerBooking', ManpowerBookingSchema);
