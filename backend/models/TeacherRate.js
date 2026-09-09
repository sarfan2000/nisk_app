const mongoose = require('mongoose');

const TeacherRateSchema = new mongoose.Schema({
    teacher: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    subject: { type: mongoose.Schema.Types.ObjectId, ref: 'Subject', required: true },
    grade: { type: mongoose.Schema.Types.ObjectId, ref: 'Grade', required: true },
    mode: { type: String, enum: ['Online', 'Offline'], required: true },
    ratePerClass: { type: Number, required: true }
});

module.exports = mongoose.model('TeacherRate', TeacherRateSchema);
