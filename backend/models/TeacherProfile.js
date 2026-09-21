const mongoose = require('mongoose');

const TeacherProfileSchema = new mongoose.Schema({
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
    qualifications: [{ type: String }],
    experience: { type: String }, // e.g. "8 Years"
    subjects: [{ type: String }],
    grades: [{ type: String }],
    modes: [{ type: String, enum: ['Online', 'Offline'] }],
    location: { type: String },
    availableDays: [{ type: String }],
    availableTime: { type: String },
    hourlyRate: { type: Number, required: true, default: 0 },
    bankInformation: { type: String },
    documents: [{ type: String }], // Optional cloud storage URLs
    profilePicture: { type: String }, // User's profile picture
    rating: { type: Number, default: 0 },
    numberOfStudents: { type: Number, default: 0 },
    shortDescription: { type: String },
    isApproved: { type: Boolean, default: true }, // Hybrid: Auto-show immediately
    isVerified: { type: Boolean, default: false } // Admin manually grants this badge
});

module.exports = mongoose.model('TeacherProfile', TeacherProfileSchema);
