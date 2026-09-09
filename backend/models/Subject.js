const mongoose = require('mongoose');

const SubjectSchema = new mongoose.Schema({
    name: { type: String, required: true },
    grade: { type: mongoose.Schema.Types.ObjectId, ref: 'Grade', required: true },
    teachers: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }], // Teachers registered for this subject
    isActive: { type: Boolean, default: true }
});

module.exports = mongoose.model('Subject', SubjectSchema);
