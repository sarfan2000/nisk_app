const mongoose = require('mongoose');

const CleaningRequestSchema = new mongoose.Schema({
    customer: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    serviceType: { type: String, required: true }, // e.g. "Deep Cleaning", "Event Cleaning", "Home Cleaning"
    location: { type: String, required: true },
    date: { type: Date, required: true },
    time: { type: String, required: true },
    propertyDetails: { type: String },
    requestedWorkersLength: { type: Number, default: 4 }, // Configurable team size
    assignedTeam: { type: mongoose.Schema.Types.ObjectId, ref: 'CleaningTeam' },
    status: {
        type: String,
        enum: ['Pending', 'Assigned', 'Job Started', 'Completed', 'Confirmed By Customer'],
        default: 'Pending'
    },
    price: { type: Number },
    createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('CleaningRequest', CleaningRequestSchema);
