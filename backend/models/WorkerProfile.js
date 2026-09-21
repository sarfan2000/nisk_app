const mongoose = require('mongoose');

const WorkerProfileSchema = new mongoose.Schema({
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
    skills: [{ type: String }],
    qualifications: [{ type: String }],
    experience: { type: String },
    expectedSalary: { type: String },
    availability: { type: String }, // e.g. "Immediate", "2 Weeks"
    rating: { type: Number, default: 0 },
    profilePicture: { type: String },
    shortDescription: { type: String },
    documents: [{ type: String }] // CV / Portfolio links
});

module.exports = mongoose.model('WorkerProfile', WorkerProfileSchema);
