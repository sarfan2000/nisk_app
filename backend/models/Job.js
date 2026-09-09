const mongoose = require('mongoose');

const JobSchema = new mongoose.Schema({
    employer: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    title: { type: String, required: true },
    company: { type: String, required: true },
    category: { type: String, required: true }, // e.g. "Cleaning", "Driver", "Construction"
    jobType: { type: String, required: true, enum: ['Full Time', 'Part Time', 'Temporary', 'Contract', 'Daily', 'Freelance'] },
    location: {
        province: { type: String },
        district: { type: String },
        city: { type: String }
    },
    salary: { type: String },
    requiredSkills: [{ type: String }],
    experienceLevel: { type: String },
    description: { type: String },
    isActive: { type: Boolean, default: true },
    createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Job', JobSchema);
