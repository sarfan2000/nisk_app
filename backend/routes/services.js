const express = require('express');
const router = express.Router();
const ServiceRequest = require('../models/ServiceRequest');
const auth = require('../middleware/auth');
const role = require('../middleware/role');

// Create service request
router.post('/request', [auth, role(['Buyer', 'Employer'])], async (req, res) => {
    try {
        const { customerId, serviceCategory, details, location, date, time } = req.body;

        const request = new ServiceRequest({
            customer: req.user.id,
            serviceCategory,
            details,
            location,
            date,
            time
        });

        await request.save();
        res.status(201).json({ msg: 'Service request submitted', request });
    } catch (err) {
        console.error(err);
        res.status(500).json({ msg: 'Server Error' });
    }
});

// Get all requests
router.get('/', [auth, role(['Admin', 'Super Admin'])], async (req, res) => {
    try {
        const requests = await ServiceRequest.find().populate('Buyer', 'name phone').populate('provider', 'name phone');
        res.json(requests);
    } catch (err) {
        console.error(err);
        res.status(500).json({ msg: 'Server Error' });
    }
});

module.exports = router;
