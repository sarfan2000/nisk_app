const mongoose = require('mongoose');

const TeacherProfileSchema = new mongoose.Schema({
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
    qualifications: [{ type: String }],
    experience: { type: String }, // e.g. "8 Years"
    subjects: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Subject' }],
    grades: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Grade' }],
    modes: [{ type: String, enum: ['Online', 'Offline'] }],
    availableDays: [{ type: String }],
    availableTime: { type: String },
    bankInformation: { type: String },
    documents: [{ type: String }], // Optional cloud storage URLs
    rating: { type: Number, default: 0 },
    numberOfStudents: { type: Number, default: 0 },
    shortDescription: { type: String }
});

module.exports = mongoose.model('TeacherProfile', TeacherProfileSchema);
