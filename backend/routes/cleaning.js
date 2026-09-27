const express = require('express');
const router = express.Router();
const CleaningRequest = require('../models/CleaningRequest');
const CleaningTeam = require('../models/CleaningTeam');
const auth = require('../middleware/auth');
const role = require('../middleware/role');

// 1. Submit Cleaning Service Request (Customer)
router.post('/request', [auth, role(['Buyer', 'Employer'])], async (req, res) => {
    try {
        const payload = { ...req.body, customer: req.user.id };
        const checkRequest = new CleaningRequest(payload);
        await checkRequest.save();
        res.status(201).json({ msg: 'Cleaning request submitted', request: checkRequest });
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// 2. Get Cleaning Requests (Admin / Supervisor)
router.get('/requests', [auth, role(['Admin', 'Super Admin'])], async (req, res) => {
    try {
        const requests = await CleaningRequest.find()
            .populate('Buyer', 'name phone')
            .populate('assignedTeam');
        res.json(requests);
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// 3. Assign Team to Request (Office Staff / Admin)
router.patch('/assign/:requestId', [auth, role(['Admin', 'Super Admin'])], async (req, res) => {
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
router.patch('/status/:requestId', [auth, role(['Admin', 'Super Admin', 'Worker'])], async (req, res) => {
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
