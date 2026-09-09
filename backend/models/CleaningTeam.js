const mongoose = require('mongoose');

const CleaningTeamSchema = new mongoose.Schema({
    name: { type: String, required: true }, // e.g. "Team 1"
    supervisor: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    workers: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }], // Up to 4 or more workers dynamically
    isActive: { type: Boolean, default: true }
});

module.exports = mongoose.model('CleaningTeam', CleaningTeamSchema);
