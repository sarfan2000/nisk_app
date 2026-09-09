const express = require('express');
const router = express.Router();
const CleaningRequest = require('../models/CleaningRequest');
const CleaningTeam = require('../models/CleaningTeam');

// 1. Submit Cleaning Service Request (Customer)
router.post('/request', async (req, res) => {
    try {
        const checkRequest = new CleaningRequest(req.body);
        await checkRequest.save();
        res.status(201).json({ msg: 'Cleaning request submitted', request: checkRequest });
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// 2. Get Cleaning Requests (Admin / Supervisor)
router.get('/requests', async (req, res) => {
    try {
        const requests = await CleaningRequest.find()
            .populate('customer', 'name phone')
            .populate('assignedTeam');
        res.json(requests);
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// 3. Assign Team to Request (Office Staff / Admin)
router.patch('/assign/:requestId', async (req, res) => {
    try {
        const { teamId } = req.body;
        const request = await CleaningRequest.findByIdAndUpdate(
            req.params.requestId,
            { assignedTeam: teamId, status: 'Assigned' },
            { new: true }
        );
        res.json({ msg: 'Team assigned successfully', request });
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// 4. Update Job Status (Supervisor / Worker)
router.patch('/status/:requestId', async (req, res) => {
    try {
        const { status } = req.body;
        const request = await CleaningRequest.findByIdAndUpdate(
            req.params.requestId,
            { status },
            { new: true }
        );
        res.json({ msg: 'Job status updated', request });
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

module.exports = router;
