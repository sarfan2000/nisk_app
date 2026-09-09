const mongoose = require('mongoose');

const WorkReportSchema = new mongoose.Schema({
    team: { type: mongoose.Schema.Types.ObjectId, ref: 'CleaningTeam', required: true },
    supervisor: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    jobRequest: { type: mongoose.Schema.Types.ObjectId, ref: 'CleaningRequest', required: true },
    date: { type: Date, required: true },
    workersInvolved: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    workCompleted: { type: String, required: true },
    issues: { type: String },
    materialsUsed: [{ type: String }],
    photos: [{ type: String }], // Cloud storage URLs
    customerConfirmation: { type: Boolean, default: false },
    supervisorComments: { type: String },
    createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('WorkReport', WorkReportSchema);
