const mongoose = require('mongoose');

const BookingSchema = new mongoose.Schema({
    student: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    bookingId: { type: String, required: true, unique: true },
    mode: { type: String, enum: ['Online', 'Offline'], required: true },
    grade: { type: mongoose.Schema.Types.ObjectId, ref: 'Grade', required: true },
    items: [{
        subject: { type: mongoose.Schema.Types.ObjectId, ref: 'Subject', required: true },
        teacher: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
        ratePerClass: { type: Number, required: true },
        numberOfClasses: { type: Number, required: true },
        schedule: { type: String }, // e.g. "Mondays 4PM"
        subtotal: { type: Number, required: true }
    }],
    totalSubtotal: { type: Number, required: true },
    serviceCharge: { type: Number, default: 0 },
    discount: { type: Number, default: 0 },
    totalBill: { type: Number, required: true },
    paymentStatus: { type: String, enum: ['Pending', 'Completed', 'Failed'], default: 'Pending' },
    status: { type: String, enum: ['Pending', 'Accepted', 'Rejected', 'Completed'], default: 'Pending' },
    createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Booking', BookingSchema);
