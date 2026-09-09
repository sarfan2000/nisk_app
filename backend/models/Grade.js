const mongoose = require('mongoose');

const GradeSchema = new mongoose.Schema({
    name: { type: String, required: true, unique: true }, // e.g. "Grade 1", "Grade 12"
    streams: [{ type: String }], // e.g. "Arts", "Commerce", "Science"
    isActive: { type: Boolean, default: true }
});

module.exports = mongoose.model('Grade', GradeSchema);
