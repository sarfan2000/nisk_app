const mongoose = require('mongoose');

const ServiceRequestSchema = new mongoose.Schema({
    customer: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    serviceCategory: { type: String, required: true },
    details: { type: String },
    location: { type: String, required: true },
    date: { type: Date },
    time: { type: String },
    status: { type: String, default: 'Pending', enum: ['Pending', 'Submitted', 'Under Review', 'Assigned', 'Accepted', 'In Progress', 'Completed', 'Cancelled', 'Rejected'] },
    provider: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    price: { type: Number },
    createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('ServiceRequest', ServiceRequestSchema);
