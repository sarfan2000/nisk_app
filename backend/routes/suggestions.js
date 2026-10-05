const express = require('express');
const router = express.Router();
const Suggestion = require('../models/Suggestion');
const auth = require('../middleware/auth');

// @route   POST /api/suggestions
// @desc    Submit a suggestion/feedback
// @access  Private
router.post('/', auth, async (req, res) => {
    try {
        const { message } = req.body;

        if (!message || message.trim() === '') {
            return res.status(400).json({ msg: 'Message is required' });
        }

        const newSuggestion = new Suggestion({
            user: req.user.id,
            message
        });

        await newSuggestion.save();
        res.status(201).json({ msg: 'Suggestion submitted successfully', suggestion: newSuggestion });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   GET /api/suggestions
// @desc    Get all suggestions (Admin only)
// @access  Private
router.get('/', auth, async (req, res) => {
    try {
        const suggestions = await Suggestion.find().sort({ createdAt: -1 }).populate('user', 'name email');
        res.json(suggestions);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

module.exports = router;
