const mongoose = require('mongoose');

const AttendanceSchema = new mongoose.Schema({
    worker: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    supervisor: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    date: { type: Date, required: true },
    checkIn: { type: String },
    checkOut: { type: String },
    status: { type: String, enum: ['Present', 'Absent', 'Leave', 'Half Day'], required: true },
    notes: { type: String },
    createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Attendance', AttendanceSchema);
